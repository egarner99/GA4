## Part A: 

1. Created a dir in egarner99: `mkdir GA4`, switched to it with: `cd GA4`
2. Initialized Git repository with: `git init`
3. Created a README.md file: `touch README.md`
4. Created dirs scripts & results: `mkdir scripts` then `mkdir results`
-  Added results/ to .gitignore: `echo "results/" > .gitignore`
- Copied in data for assignment: `cp -rv ../garrigos-data/fastq data`
- Added data/ to .gitignore: `echo "data/" >> .gitignore`
5. Made the trimgalore.sh file: `touch scripts/trimgalore.sh`
- Copied in the starting script in the assignment:
```bash
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
```

<br>

## Part B:

6. Added the following options underneath the #!/bin/bash for the SBATCH options: 
```bash
#SBATCH --account=PAS2880
#SBATCH --cpus-per-task=8
#SBATCH --time=80
#SBATCH --output=slurm-trimgalore-%j.out
#SBATCH --mail-type=FAIL
```
7. Checked the trim_galore by: 
```bash
TRIMGALORE_CONTAINER=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e

apptainer exec "$TRIMGALORE_CONTAINER" trim_galore --help
```

- The TrimGalore option to specify how many cores is: `-j <number>` or `--cores <number>`

- The script section for the command was changed to this: 
```bash
# Run TrimGalore
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"
 ```

8. I used the command: `sbatch scripts/trimgalore.sh ../garrigos-data/fastq/ERR10802863_R1.fastq.gz ../garrigos-data/fastq/ERR10802863_R2.fastq.gz results/fastq`

And got the output: `Submitted batch job 37876463`

I unfortunately didn't catch the job pending, but I did catch it running by by entering: `squeue -u $USER -l`

```bash
Sun Oct 19 20:33:42 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37876463       cpu trimgalo egarner9  RUNNING       0:14   1:20:00      1 p0001
          37875093       cpu ondemand egarner9  RUNNING    1:22:38   2:00:00      1 p0224
```

It eventually disappeared as well, letting me know the job was done:
```bash
Sun Oct 19 20:34:00 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37875093       cpu ondemand egarner9  RUNNING    1:22:56   2:00:00      1 p0224
```

I also checked if the SLURM file was present by using `ls` and got the output: `data  README.md  results  scripts  slurm-trimgalore-37876463.out`

The Slurm file also had the final logging statements, letting me know that the job completed successfully: 
```bash
# TrimGalore version:
INFO:    Using cached SIF image
INFO:    gocryptfs not found, will not be able to use gocryptfs

                        Quality-/Adapter-/RRBS-/Speciality-Trimming
                                [powered by Cutadapt]
                                  version 0.6.10

                               Last update: 02 02 2023

# Successfully finished script trimgalore.sh
Sun Oct 19 08:33:53 PM EDT 2025
```

I removed all the outputs by: `rm slurm-trimgalore*` and then `rm results/fastq/ERR10802863_R*`

10. I reran the job to check, yes I did notice one long string of G's in the file. There were a couple in sets of three as well in the middle-ish of the reads, but I wasn't sure if they were originally N's. (redeleted the files using the same process as previously). 

11. I reloaded the tab, so I had reassign TRIMGALORE_CONTAINER: `TRIMGALORE_CONTAINER=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e`

Then I used the same command previously: `apptainer exec "$TRIMGALORE_CONTAINER" trim_galore --help`

I think the TrimGalore option I need is `--trim-n`. I added it the script as follows (I believe in this spot below --paired, I unfortunately don't remember the exact placement): 
```bash
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --paired \
    --trim-n \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"
```

I than ran the command: `sbatch scripts/trimgalore.sh ../garrigos-data/fastq/ERR10802863_R1.fastq.gz ../garrigos-data/fastq/ERR10802863_R2.fastq.gz results/fastq`

With the output: `Submitted batch job 37876543`

This unfortunately didn't make a difference, I tried moving `--trim-n` around, and also tried a few different options, for example `--quality 20` or `--2color 2`, but none of them worked.

I finally tried: 
```bash
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --adapter2 "G{10}" \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"
```

I checked the .html files, and it seemed to work to eliminate the G's from the ends for the same R2 file. Again, I wasn't sure if the three sets of G's in the middle of the reads were supposed to be N's, so I left them alone.

I also checked the .html files using simply `--adapter "G{20}" to see if it would work too and it did! I think it might be best to use this one, in case strings of G's also appeared on the R1 file:

```bash
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --adapter "G{10}" \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"
```


12. As mentioned in Q11, the new script option that worked for me was (along with --adapter2 "G{20}" instead):
```bash
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --adapter "G{10}" \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"
```

There were also these outputs for R1 and R2 in the trimmng reports: 

- R1: `Sequence: GGGGGGGGGG; Type: regular 3'; Length: 10; Trimmed: 131324 times`
- R2: `Sequence: GGGGGGGGGG; Type: regular 3'; Length: 10; Trimmed: 155483 times`

<br>

Bonus Question: Though I unforunately couldn't get it to work, this was the change to the script that I attempted:
```bash
# Replacing R1 names
sample_id=$(apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --adapter "G{10}" \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R1")

R1_out_init="$outdir"/$(basename "$sample_id"_R1.fastq.gz)

mv "$outdir"/"$R1_out_init"_R1.fastq.gz "$R1_out_init"

# Replacing R2 names
sample_id2=$(apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --cores 8 \
    --adapter "G{10}" \
    --paired \
    --fastqc \
    --output_dir "$outdir" \
    "$R2")

R2_out_init="$outdir"/$(basename "$sample_id2")

mv "$outdir"/"$R2_out_init"_R2.fastq.gz "$R2_out_init"
```

