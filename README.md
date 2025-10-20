## Part A: 

1. Created a dir in egarner99: `mkdir GA4`, switched to it with: `cd GA4`
2. Initialized Git repository with: `git init`
3. Created a README.md file: `touch README.md`
4. Created dirs scripts & results: `mkdir scripts` then `mkdir results`
-  Added results/ to .gitignore: `echo "results/" > .gitignore`
- Copied in fastq data to data dir: `cp -rv ../garrigos-data/fastq data` (this step was accidentally skipped until the end, added back after Q14 in Part C)
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

9. I unfortunately didn't catch the job pending, but I did catch it running by by entering: `squeue -u $USER -l`

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

<br>

## Part C:

13. I first tested it using the input:
```bash
for fastq in ../garrigos-data/fastq/*fastq.gz; do
  echo sbatch scripts/trimgalore.sh "$fastq" results/fastqc
done
```
Then ran the job using:
for R1 in ../garrigos-data/fastq/*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$fastq" results/fastqc
done

But it didn't work. After working with it a bit more, my output was:

```bash
for R1 in ../garrigos-data/fastq/*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$R1" "$R2" results/fastq
done
```
I got the output: 
```bash
Submitted batch job 37879025
Submitted batch job 37879026
Submitted batch job 37879027
Submitted batch job 37879028
Submitted batch job 37879029
Submitted batch job 37879030
Submitted batch job 37879031
Submitted batch job 37879032
Submitted batch job 37879033
Submitted batch job 37879034
Submitted batch job 37879035
Submitted batch job 37879036
Submitted batch job 37879037
Submitted batch job 37879038
Submitted batch job 37879039
Submitted batch job 37879040
Submitted batch job 37879041
Submitted batch job 37879042
Submitted batch job 37879043
Submitted batch job 37879044
Submitted batch job 37879045
Submitted batch job 37879046
```

14. I watched the job using the `squeue -u $USER -l` command. It went by pretty fast, but the ones I caught were:

```bash
Sun Oct 19 23:40:35 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37876801       cpu ondemand egarner9  RUNNING      27:28   2:00:00      1 p0224
          37879046 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879045 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879044 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879043 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879042 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879041 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879040 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879039 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879038 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879037 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879036 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879035 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879034 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879033 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879032 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879031 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (None)
          37879030 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
          37879029 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
          37879028 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
          37879027 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
          37879026 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
          37879025 cpu,cpu-e trimgalo egarner9  PENDING       0:00   1:20:00      1 (Reservation)
```
```bash
Sun Oct 19 23:41:10 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37879025       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0001
          37879026       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0012
          37879027       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0023
          37879028       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0023
          37879029       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0197
          37879030       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0198
          37879031       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0157
          37879032       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0157
          37879033       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0157
          37879034       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0158
          37879035       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0158
          37879036       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0158
          37879037       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0223
          37879038       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0223
          37879039       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0223
          37879040       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0224
          37879041       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0224
          37879042       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0224
          37879043       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0016
          37879044       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0017
          37879045       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0017
          37879046       cpu trimgalo egarner9  RUNNING       0:16   1:20:00      1 p0014
          37876801       cpu ondemand egarner9  RUNNING      28:03   2:00:00      1 p0224
```

```bash
Sun Oct 19 23:41:30 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37876801       cpu ondemand egarner9  RUNNING      28:23   2:00:00      1 p0224
```


I used `-ls` to check that the slurm files were there:

```bash
data                           slurm-trimgalore-37879030.out  slurm-trimgalore-37879039.out
README.md                      slurm-trimgalore-37879031.out  slurm-trimgalore-37879040.out
results                        slurm-trimgalore-37879032.out  slurm-trimgalore-37879041.out
scripts                        slurm-trimgalore-37879033.out  slurm-trimgalore-37879042.out
slurm-trimgalore-37879025.out  slurm-trimgalore-37879034.out  slurm-trimgalore-37879043.out
slurm-trimgalore-37879026.out  slurm-trimgalore-37879035.out  slurm-trimgalore-37879044.out
slurm-trimgalore-37879027.out  slurm-trimgalore-37879036.out  slurm-trimgalore-37879045.out
slurm-trimgalore-37879028.out  slurm-trimgalore-37879037.out  slurm-trimgalore-37879046.out
slurm-trimgalore-37879029.out  slurm-trimgalore-37879038.out
```

I also went through a few to make sure the final logging messages were there.

I moved the slurm log files to results/logs by:  
`mkdir results/logs` then `mv slurm-trimgalore* results/logs`.
