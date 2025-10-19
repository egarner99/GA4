#!/bin/bash
set -euo pipefail

# Constants
TRIMGALORE_CONTAINER=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e

# Copy the placeholder variables
R1="$1"
R2="$2"
outdir="$3"

# Report
echo "# Starting script trimgalore.sh"
date
echo "# Input R1 FASTQ file:      $R1"
echo "# Input R2 FASTQ file:      $R2"
echo "# Output dir:               $outdir"
echo

# Create the output dir
mkdir -p "$outdir"

# Run TrimGalore
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"

# Report
echo
echo "# TrimGalore version:"
apptainer exec "$TRIMGALORE_CONTAINER" \
  trim_galore -v
echo "# Successfully finished script trimgalore.sh"
date