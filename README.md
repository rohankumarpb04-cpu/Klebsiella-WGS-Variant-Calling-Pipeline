# Klebsiella-WGS-Variant-Calling-Pipeline
# 🧬 Klebsiella pneumoniae Whole Genome Sequencing (WGS) Variant Calling Pipeline

## 📖 Overview

This project presents an automated **Whole Genome Sequencing (WGS) Variant Calling Pipeline** for *Klebsiella pneumoniae* developed using Bash scripting in a Linux environment.

The pipeline performs an end-to-end analysis of paired-end Illumina sequencing data, starting from raw sequencing reads downloaded from the NCBI Sequence Read Archive (SRA) and ending with functional annotation of genetic variants using SnpEff and extraction of biologically significant variants.

---

## 🚀 Pipeline Workflow

```
NCBI SRA
     │
     ▼
Download Sequencing Data
     │
     ▼
FASTQ Generation
     │
     ▼
Quality Control (FastQC)
     │
     ▼
Read Trimming (fastp)
     │
     ▼
Quality Control of Trimmed Reads
     │
     ▼
Reference Genome Preparation
     │
     ▼
Read Alignment (BWA-MEM)
     │
     ▼
SAM → BAM Conversion
     │
     ▼
Sorting & Indexing (SAMtools)
     │
     ▼
Variant Calling (BCFtools)
     │
     ▼
Variant Filtering
     │
     ▼
Functional Annotation (SnpEff)
     │
     ▼
Extraction of HIGH & MODERATE Impact Variants
     │
     ▼
Automatic Summary Report
```

---

## 🛠️ Tools Used

| Tool               | Purpose                     |
| ------------------ | --------------------------- |
| Bash               | Pipeline automation         |
| Linux (Ubuntu/WSL) | Analysis environment        |
| SRA Toolkit        | Download sequencing data    |
| FastQC             | Quality assessment          |
| fastp              | Read trimming & filtering   |
| BWA-MEM            | Sequence alignment          |
| SAMtools           | BAM processing              |
| BCFtools           | Variant calling & filtering |
| SnpEff             | Functional annotation       |
| SnpSift            | Variant filtering           |

---

## 📂 Project Structure

```
Klebsiella-WGS-Variant-Calling-Pipeline/
│
├── scripts/
│   └── klebsiella_pipeline.sh
│
├── sample_outputs/
│   ├── pipeline_summary.txt
│   ├── SRR39683479_high_impact.vcf
│   └── variant_stats.txt
│
├── docs/
│
├── images/
│
├── README.md
├── LICENSE
└── .gitignore
```

---

## 📋 Pipeline Features

* Automated end-to-end WGS analysis
* Quality control of raw and trimmed reads
* Adapter removal and quality filtering
* Reference genome indexing
* Read alignment using BWA-MEM
* SAM to BAM conversion
* BAM sorting and indexing
* Variant calling using BCFtools
* Variant filtering
* Functional annotation using SnpEff
* Extraction of HIGH and MODERATE impact variants
* Automatic generation of analysis summary report
* Skip completed steps to allow pipeline resume without repeating completed analyses

---

## 📊 Example Output

```
==========================================
Klebsiella pneumoniae Variant Analysis
==========================================

Sample          Total Variants    High+Moderate
--------------------------------------------------------------
SRR39683479     32542             5350
SRR39683478     32437             5335
SRR39683470     32903             5347
SRR39683469     32432             5295
SRR39683468     32261             5291

Pipeline completed successfully.
```

---

## 🧪 Dataset

**Organism:** *Klebsiella pneumoniae*

Reference Genome:

GCF_000016305.1

Sequencing samples:

* SRR39683479
* SRR39683478
* SRR39683470
* SRR39683469
* SRR39683468

---

## ▶️ Running the Pipeline

Clone the repository:

```bash
git clone https://github.com/yourusername/Klebsiella-WGS-Variant-Calling-Pipeline.git
cd Klebsiella-WGS-Variant-Calling-Pipeline
```

Make the script executable:

```bash
chmod +x scripts/klebsiella_pipeline.sh
```

Run the pipeline:

```bash
./scripts/klebsiella_pipeline.sh
```

---

## 📁 Output Files

The pipeline automatically generates:

* FastQC Reports
* Trimmed FASTQ files
* Sorted BAM files
* BAM Index files
* Filtered VCF files
* Annotated VCF files
* HIGH & MODERATE impact variant files
* Pipeline Summary Report

---

## 💡 Skills Demonstrated

* Bioinformatics Pipeline Development
* Linux Command Line
* Bash Scripting
* Next Generation Sequencing (NGS)
* Whole Genome Sequencing (WGS)
* Variant Calling
* Functional Variant Annotation
* Genomic Data Analysis
* Workflow Automation

---

## 📌 Future Improvements

* Multi-thread optimization
* Logging system
* Pipeline configuration file
* Visualization of variant statistics
* Docker support
* Snakemake / Nextflow implementation

---

## 👨‍💻 Author

**Rohan**

M.Sc. Bioinformatics

---

## 📄 License

This project is licensed under the MIT License.
