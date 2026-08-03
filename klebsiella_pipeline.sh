#!/bin/bash

# ============================================
# Klebsiella pneumoniae Variant Calling Pipeline
# Author: Your Name
# ============================================

echo "=========================================="
echo "Klebsiella pneumoniae NGS Pipeline Started"
echo "=========================================="

# Project directory
PROJECT_DIR="/mnt/c/ngs/klebsiella_pipeline"

# Raw reads
RAW="$PROJECT_DIR/raw_reads"

# Reference genome
REF="$PROJECT_DIR/reference"

# Reference FASTA
REFERENCE="$REF/ncbi_dataset/data/GCF_000016305.1/reference.fasta"

# Results
QC="$PROJECT_DIR/results/qc"
TRIM="$PROJECT_DIR/results/trimmed"
ALIGN="$PROJECT_DIR/results/alignment"
VAR="$PROJECT_DIR/results/variants"
ANN="$PROJECT_DIR/results/annotation"

echo "Project directory loaded successfully."
#############################################################
# Sample IDs
#############################################################

SAMPLES=(
SRR39683479
SRR39683478
SRR39683470
SRR39683469
SRR39683468
)

echo ""
echo "Samples to process:"
for SAMPLE in "${SAMPLES[@]}"
do
    echo " - $SAMPLE"
done

#############################################################
# Check Required Software
#############################################################

TOOLS=(
prefetch
fasterq-dump
fastqc
fastp
bwa
samtools
bcftools
picard
snpEff
snpSift
pigz
)

echo ""
echo "Checking required software..."
echo "--------------------------------"

for TOOL in "${TOOLS[@]}"
do
    if command -v $TOOL >/dev/null 2>&1
    then
        echo "[OK] $TOOL"
    else
        echo "[MISSING] $TOOL"
    fi
done

echo "--------------------------------"
echo "Software check completed."
#############################################################
# Download SRA Data
#############################################################

echo ""
echo "============================================="
echo "Downloading Klebsiella pneumoniae datasets"
echo "============================================="

cd "$RAW" || exit

SAMPLES=(
SRR39683479
SRR39683478
SRR39683470
SRR39683469
SRR39683468
)

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""
    echo "-----------------------------------------"
    echo "Processing Sample: $SAMPLE"
    echo "-----------------------------------------"

    # Download only if SRA folder does not exist
    if [ ! -d "$SAMPLE" ]; then
        echo "Downloading $SAMPLE..."
        prefetch "$SAMPLE"
    else
        echo "$SAMPLE already downloaded."
    fi

    # Convert SRA to FASTQ only if FASTQ files do not exist
    if [ ! -f "${SAMPLE}_1.fastq.gz" ]; then
        echo "Converting $SAMPLE to FASTQ..."
        fasterq-dump "$SAMPLE" --split-files -e 4
    else
        echo "FASTQ files already exist."
    fi

    # Compress FASTQ files
    if [ -f "${SAMPLE}_1.fastq" ]; then
        pigz -p 4 "${SAMPLE}_1.fastq"
    fi

    if [ -f "${SAMPLE}_2.fastq" ]; then
        pigz -p 4 "${SAMPLE}_2.fastq"
    fi

    echo "$SAMPLE completed."
done

echo ""
echo "============================================="
echo "All datasets downloaded successfully."
echo "============================================="
#############################################################
# STEP 4 : FASTQC
#############################################################

echo ""
echo "========================================"
echo "STEP 4 : Running FastQC"
echo "========================================"

mkdir -p "$QC"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$QC/${SAMPLE}_1_fastqc.html" ] && \
       [ -f "$QC/${SAMPLE}_2_fastqc.html" ]; then

        echo "✓ FastQC already completed for $SAMPLE. Skipping..."

    else

        echo "Running FastQC for $SAMPLE..."

        fastqc \
            "$RAW/${SAMPLE}_1.fastq.gz" \
            "$RAW/${SAMPLE}_2.fastq.gz" \
            --outdir "$QC"

        echo "✓ FastQC completed for $SAMPLE"

    fi
done

echo ""
echo "========================================"
echo "FastQC Completed Successfully"
echo "========================================"

#############################################################
# STEP 5 : READ TRIMMING USING FASTP
#############################################################

echo ""
echo "========================================"
echo "STEP 5 : Running fastp"
echo "========================================"

mkdir -p "$TRIM"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$TRIM/${SAMPLE}_R1_trimmed.fastq.gz" ] && \
       [ -f "$TRIM/${SAMPLE}_R2_trimmed.fastq.gz" ] && \
       [ -f "$TRIM/${SAMPLE}_fastp.html" ] && \
       [ -f "$TRIM/${SAMPLE}_fastp.json" ]; then

        echo "✓ Trimming already completed for $SAMPLE. Skipping..."

    else

        echo "Processing $SAMPLE..."

        fastp \
            -i "$RAW/${SAMPLE}_1.fastq.gz" \
            -I "$RAW/${SAMPLE}_2.fastq.gz" \
            -o "$TRIM/${SAMPLE}_R1_trimmed.fastq.gz" \
            -O "$TRIM/${SAMPLE}_R2_trimmed.fastq.gz" \
            --detect_adapter_for_pe \
            --thread 4 \
            --html "$TRIM/${SAMPLE}_fastp.html" \
            --json "$TRIM/${SAMPLE}_fastp.json"

        if [ $? -eq 0 ]; then
            echo "✓ Completed trimming for $SAMPLE"
        else
            echo "✗ ERROR: fastp failed for $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "fastp Completed Successfully"
echo "========================================"

#############################################################
# STEP 6 : FASTQC ON TRIMMED READS
#############################################################

echo ""
echo "========================================"
echo "STEP 6 : FastQC on Trimmed Reads"
echo "========================================"

mkdir -p "$QC/trimmed_fastqc"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$QC/trimmed_fastqc/${SAMPLE}_R1_trimmed_fastqc.html" ] && \
       [ -f "$QC/trimmed_fastqc/${SAMPLE}_R2_trimmed_fastqc.html" ]; then

        echo "✓ Trimmed FastQC already completed for $SAMPLE. Skipping..."

    else

        echo "Running FastQC on trimmed reads: $SAMPLE"

        fastqc \
            "$TRIM/${SAMPLE}_R1_trimmed.fastq.gz" \
            "$TRIM/${SAMPLE}_R2_trimmed.fastq.gz" \
            --outdir "$QC/trimmed_fastqc"

        if [ $? -eq 0 ]; then
            echo "✓ Completed FastQC for $SAMPLE"
        else
            echo "✗ ERROR: FastQC failed for $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "Trimmed FastQC Completed Successfully"
echo "========================================"

#############################################################
# STEP 7 : PREPARE REFERENCE GENOME
#############################################################

echo ""
echo "========================================"
echo "STEP 7 : Preparing Reference Genome"
echo "========================================"

cd "$REF/ncbi_dataset/data/GCF_000016305.1"

# Rename genome only if needed
if [ ! -f reference.fasta ]; then
    mv GCF_000016305.1_ASM1630v1_genomic.fna reference.fasta
fi

echo ""

if [ ! -f reference.fasta.bwt ]; then
    echo "Building BWA index..."
    bwa index reference.fasta
else
    echo "BWA index already exists. Skipping..."
fi

echo ""

if [ ! -f reference.fasta.fai ]; then
    echo "Building FASTA index..."
    samtools faidx reference.fasta
else
    echo "FASTA index already exists. Skipping..."
fi

echo ""
echo "========================================"
echo "Reference Genome Ready"
echo "========================================"

#############################################################
# STEP 8 : ALIGN READS USING BWA-MEM
#############################################################

echo ""
echo "========================================"
echo "STEP 8 : Aligning Reads"
echo "========================================"

# Create alignment directory if it doesn't exist 
mkdir -p "$ALIGN"

# Loop through all samples
for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    # Skip if SAM file already exists
    if [ -f "$ALIGN/${SAMPLE}.sam" ]; then
        echo "SAM file already exists for $SAMPLE. Skipping alignment."

    else
        echo "Aligning $SAMPLE..."

        bwa mem \
            -t 4 \
            "$REFERENCE" \
            "$TRIM/${SAMPLE}_R1_trimmed.fastq.gz" \
            "$TRIM/${SAMPLE}_R2_trimmed.fastq.gz" \
            > "$ALIGN/${SAMPLE}.sam"

        echo "Alignment completed for $SAMPLE"
    fi

done

echo ""
echo "========================================"
echo "All Alignments Completed"
echo "========================================"

#############################################################
# STEP 9 : CONVERT SAM TO BAM
#############################################################

echo ""
echo "========================================"
echo "STEP 9 : Converting SAM to BAM"
echo "========================================"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    # Skip if BAM already exists
    if [ -f "$ALIGN/${SAMPLE}.bam" ]; then

        echo "✓ BAM already exists for $SAMPLE. Skipping..."

    else

        echo "Converting $SAMPLE..."

        samtools view \
            -@ 4 \
            -bS \
            "$ALIGN/${SAMPLE}.sam" \
            > "$ALIGN/${SAMPLE}.bam"

        if [ $? -eq 0 ]; then
            echo "✓ BAM created successfully for $SAMPLE"
        else
            echo "✗ ERROR while converting $SAMPLE"
            exit 1
        fi

    fi

done

echo ""
echo "========================================"
echo "SAM to BAM Conversion Completed"
echo "========================================"

#############################################################
# STEP 10 : SORT BAM FILES
#############################################################

echo ""
echo "========================================"
echo "STEP 10 : Sorting BAM Files"
echo "========================================"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$ALIGN/${SAMPLE}_sorted.bam" ]; then

        echo "✓ Sorted BAM already exists for $SAMPLE. Skipping..."

    else

        echo "Sorting $SAMPLE..."

        samtools sort \
            -@ 4 \
            -o "$ALIGN/${SAMPLE}_sorted.bam" \
            "$ALIGN/${SAMPLE}.bam"

        if [ $? -eq 0 ]; then
            echo "✓ Sorted BAM created successfully for $SAMPLE"
        else
            echo "✗ ERROR while sorting $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "BAM Sorting Completed Successfully"
echo "========================================"

#############################################################
# STEP 11 : INDEX SORTED BAM FILES
#############################################################

echo ""
echo "========================================"
echo "STEP 11 : Indexing Sorted BAM Files"
echo "========================================"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$ALIGN/${SAMPLE}_sorted.bam.bai" ]; then

        echo "✓ BAM index already exists for $SAMPLE. Skipping..."

    else

        echo "Indexing $SAMPLE..."

        samtools index \
            -@ 4 \
            "$ALIGN/${SAMPLE}_sorted.bam"

        if [ $? -eq 0 ]; then
            echo "✓ BAM indexed successfully for $SAMPLE"
        else
            echo "✗ ERROR while indexing $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "BAM Indexing Completed Successfully"
echo "========================================"

#############################################################
# STEP 12 : VARIANT CALLING
#############################################################

echo ""
echo "========================================"
echo "STEP 12 : Variant Calling"
echo "========================================"

mkdir -p "$VAR"

REFERENCE="$REF/ncbi_dataset/data/GCF_000016305.1/reference.fasta"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$VAR/${SAMPLE}.vcf.gz" ]; then

        echo "✓ Variant file already exists for $SAMPLE. Skipping..."

    else

        echo "Calling variants for $SAMPLE..."

        bcftools mpileup \
            -Ou \
            -f "$REFERENCE" \
            "$ALIGN/${SAMPLE}_sorted.bam" | \
        bcftools call \
            -mv \
            -Oz \
            -o "$VAR/${SAMPLE}.vcf.gz"

        if [ $? -eq 0 ]; then

            echo "Indexing VCF..."

            bcftools index "$VAR/${SAMPLE}.vcf.gz"

            echo "✓ Variant calling completed for $SAMPLE"

        else

            echo "✗ ERROR during variant calling for $SAMPLE"
            exit 1

        fi

    fi

done

echo ""
echo "========================================"
echo "Variant Calling Completed Successfully"
echo "========================================"

#############################################################
# STEP 13 : FILTER VARIANTS
#############################################################

echo ""
echo "========================================"
echo "STEP 13 : Filtering Variants"
echo "========================================"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$VAR/${SAMPLE}_filtered.vcf.gz" ]; then

        echo "✓ Filtered VCF already exists for $SAMPLE. Skipping..."

    else

        echo "Filtering variants for $SAMPLE..."

        bcftools filter \
            -i 'QUAL>30 && DP>10' \
            -Oz \
            -o "$VAR/${SAMPLE}_filtered.vcf.gz" \
            "$VAR/${SAMPLE}.vcf.gz"

        bcftools index "$VAR/${SAMPLE}_filtered.vcf.gz"

        if [ $? -eq 0 ]; then
            echo "✓ Variant filtering completed for $SAMPLE"
        else
            echo "✗ ERROR while filtering $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "Variant Filtering Completed Successfully"
echo "========================================"

#############################################################
# STEP 14 : VARIANT STATISTICS
#############################################################

echo ""
echo "========================================"
echo "STEP 14 : Generating Variant Statistics"
echo "========================================"

mkdir -p "$VAR/stats"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$VAR/stats/${SAMPLE}.stats" ]; then

        echo "✓ Statistics already exist for $SAMPLE. Skipping..."

    else

        echo "Generating statistics for $SAMPLE..."

        bcftools stats \
            "$VAR/${SAMPLE}_filtered.vcf.gz" \
            > "$VAR/stats/${SAMPLE}.stats"

        if [ $? -eq 0 ]; then
            echo "✓ Statistics generated for $SAMPLE"
        else
            echo "✗ ERROR generating statistics for $SAMPLE"
            exit 1
        fi

    fi
done

echo ""
echo "========================================"
echo "Variant Statistics Completed Successfully"
echo "========================================"

#############################################################
# STEP 15 : VARIANT ANNOTATION (SnpEff)
#############################################################

echo ""
echo "========================================"
echo "STEP 15 : Variant Annotation"
echo "========================================"

mkdir -p "$ANN"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$ANN/${SAMPLE}_annotated.vcf" ]; then

        echo "✓ Annotation already completed for $SAMPLE. Skipping..."

    else

        echo "Annotating variants for $SAMPLE..."

        snpEff \
            K_pneumoniae \
            "$VAR/${SAMPLE}_filtered.vcf.gz" \
            > "$ANN/${SAMPLE}_annotated.vcf"

        if [ $? -eq 0 ]; then
            echo "✓ Annotation completed for $SAMPLE"
        else
            echo "✗ ERROR during annotation for $SAMPLE"
            exit 1
        fi

    fi

done

echo ""
echo "========================================"
echo "Variant Annotation Completed Successfully"
echo "========================================"

#############################################################
# STEP 16 : EXTRACT HIGH & MODERATE IMPACT VARIANTS
#############################################################

echo ""
echo "========================================"
echo "STEP 16 : Extracting HIGH & MODERATE Impact Variants"
echo "========================================"

mkdir -p "$ANN/high_impact"

for SAMPLE in "${SAMPLES[@]}"
do
    echo ""

    if [ -f "$ANN/high_impact/${SAMPLE}_high_impact.vcf" ]; then

        echo "✓ High-impact file already exists for $SAMPLE. Skipping..."

    else

        echo "Extracting HIGH & MODERATE variants for $SAMPLE..."

        # Keep VCF header
        grep "^#" "$ANN/${SAMPLE}_annotated.vcf" \
        > "$ANN/high_impact/${SAMPLE}_high_impact.vcf"

        # Keep only HIGH or MODERATE annotations
        grep -E "HIGH|MODERATE" \
        "$ANN/${SAMPLE}_annotated.vcf" \
        >> "$ANN/high_impact/${SAMPLE}_high_impact.vcf"

        echo "✓ Extraction completed for $SAMPLE"

    fi

done

echo ""
echo "========================================"
echo "High & Moderate Variant Extraction Completed"
echo "========================================"

#############################################################
# STEP 17 : GENERATE FINAL SUMMARY REPORT
#############################################################

echo ""
echo "========================================"
echo "STEP 17 : Generating Final Summary Report"
echo "========================================"

REPORT="$PROJECT_DIR/results/pipeline_summary.txt"

echo "==========================================" > "$REPORT"
echo "Klebsiella pneumoniae Variant Analysis" >> "$REPORT"
echo "==========================================" >> "$REPORT"
echo "" >> "$REPORT"

printf "%-15s %-15s %-20s\n" \
"Sample" "Total_Variants" "High+Moderate" >> "$REPORT"

echo "--------------------------------------------------------------" >> "$REPORT"

for SAMPLE in "${SAMPLES[@]}"
do
    TOTAL=$(zgrep -vc "^#" "$VAR/${SAMPLE}_filtered.vcf.gz")

    HIGH_MOD=$(grep -vc "^#" "$ANN/high_impact/${SAMPLE}_high_impact.vcf")

    printf "%-15s %-15s %-20s\n" \
    "$SAMPLE" "$TOTAL" "$HIGH_MOD" >> "$REPORT"

done

echo "" >> "$REPORT"
echo "Pipeline completed successfully." >> "$REPORT"
echo "Generated on: $(date)" >> "$REPORT"

echo ""
echo "========================================"
echo "Pipeline Summary Report Created"
echo "Location: $REPORT"
echo "========================================"
