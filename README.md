## Part A: 

1. Created a dir in egarner99: `mkdir GA4`, switched to it with: `cd GA4`
2. Initialized Git repository with: `git init`
3. Created a README.md file: `touch README.md`
4. Created dirs scripts & results: `mkdir scripts` then `mkdir results`
-  Added results/ to .gitignore: `echo "results/" > .gitignore`
- Copied in fastq data to data dir: `cp -rv ../garrigos-data/fastq data` (seemed to have skipped this step, went back and redid some of the sections with the correct command using this data, previous work can be seen in the repository or was still left in the answer!)
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

At the end of the assignment, I noticed that I had put 80 instead of 30 minutes in this section, and edited it in the script:
```bash
#SBATCH --account=PAS2880
#SBATCH --cpus-per-task=8
#SBATCH --time=30
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

8. I used the command: 

```bash
sbatch scripts/trimgalore.sh data/fastq/ERR10802863_R1.fastq.gz data/fastq/ERR10802863_R2.fastq.gz results/fastq
```

And got the output: 
```bash
Submitted batch job 37899642
```

9. I unfortunately didn't catch the job pending, but I did catch it running by by entering: `squeue -u $USER -l`

```bash
Mon Oct 20 10:41:47 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37899642       cpu trimgalo egarner9  RUNNING       0:13     30:00      1 p0164
          37898612       cpu ondemand egarner9  RUNNING      27:04   2:00:00      1 p0224
```

```bash
Mon Oct 20 10:41:59 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37898612       cpu ondemand egarner9  RUNNING      27:16   2:00:00      1 p0224
```

I also checked if the SLURM file was present by using `ls` and got the output: 
```bash
data  README.md  results  scripts  slurm-trimgalore-37899642.out
```

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
Mon Oct 20 10:41:57 AM EDT 2025
```

I removed all the outputs by: `rm slurm-trimgalore-37899642.out` and then `rm results/fastq/ERR10802863_R*`

10. Yes I did notice one long string of G's in the file (when running my code yesterday with the garrigos-data, not from data dir). There were a couple in sets of three as well in the middle-ish of the reads, but I wasn't sure if they were originally N's. (redeleted the files using the same process as previously). 

11. I checked the help section:
```bash
TRIMGALORE_CONTAINER=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e
```

Then I used the same command previously: 
```bash
apptainer exec "$TRIMGALORE_CONTAINER" trim_galore --help
```

Yesterday (unfortunately using the data from garrigos-data, not the data dir for the command), I originally thought the TrimGalore option I needed was `--trim-n`. I added it the script as follows (I believe in this spot below --paired, I unfortunately don't remember the exact placement): 
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

I than ran the command: 
```bash
sbatch scripts/trimgalore.sh ../garrigos-data/fastq/ERR10802863_R1.fastq.gz ../garrigos-data/fastq/ERR10802863_R2.fastq.gz results/fastq
```

With the output: `Submitted batch job 37876543`


This unfortunately didn't make a difference, I tried moving `--trim-n` around, and also tried a few different options, for example `--quality 20` or `--2color 2`, but none of them worked.

I finally tried `-adapter2 "G{10}"` and `-adapter "G{10}"` yesterday, added as follows:
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
I think it might be best to use this one, in case strings of G's also appeared on the R1 file:

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
But I used the wrong code. I reran the `--adapter "G{10}"` job today with the correct code: 

```bash
sbatch scripts/trimgalore.sh data/fastq/ERR10802863_R1.fastq.gz data/fastq/ERR10802863_R2.fastq.gz results/fastq
```

I checked the .html files, and it seemed to work to eliminate the G's from the ends for the same R2 file. Again, I wasn't sure if the three sets of G's in the middle of the reads were supposed to be N's, so I left them alone.

12. As mentioned in Q11, the new script option that worked for me was (along with --adapter2 "G{10}" instead):
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

- R1: 
```bash
Sequence: GGGGGGGGGG; Type: regular 3'; Length: 10; Trimmed: 131324 times
```
- R2: 
```bash
Sequence: GGGGGGGGGG; Type: regular 3'; Length: 10; Trimmed: 155483 times
```

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
```bash
for R1 in ../garrigos-data/fastq/*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$fastq" results/fastqc
done
```

But it didn't work, so I then tried the input:

```bash
for R1 in ../garrigos-data/fastq/*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$R1" "$R2" results/fastq
done
```

Finally, I re-ran it using the correct dir for the data:
```bash 
for R1 in data/fastq/*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$R1" "$R2" results/fastq
done
```

I got the output: 
```bash
Submitted batch job 37898878
Submitted batch job 37898879
Submitted batch job 37898880
Submitted batch job 37898881
Submitted batch job 37898882
Submitted batch job 37898883
Submitted batch job 37898884
Submitted batch job 37898885
Submitted batch job 37898886
Submitted batch job 37898887
Submitted batch job 37898888
Submitted batch job 37898889
Submitted batch job 37898890
Submitted batch job 37898891
Submitted batch job 37898892
Submitted batch job 37898893
Submitted batch job 37898894
Submitted batch job 37898895
Submitted batch job 37898896
Submitted batch job 37898897
Submitted batch job 37898898
Submitted batch job 37898899
```

14. I watched the job using the `squeue -u $USER -l` command. It went by pretty fast, but a few were:

```bash
Mon Oct 20 10:38:14 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37898880       cpu trimgalo egarner9 COMPLETI       0:23     30:00      1 p0027
          37898881       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0027
          37898882       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0027
          37898883       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0032
          37898884       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898885       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898886       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898887       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898888       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0003
          37898889       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0006
          37898890       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898891       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898892       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898893       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898894       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898895       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898896       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898897       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898898       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0007
          37898899       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0010
          37898612       cpu ondemand egarner9  RUNNING      23:31   2:00:00      1 p0224
```
```bash
Mon Oct 20 10:38:14 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37898880       cpu trimgalo egarner9 COMPLETI       0:23     30:00      1 p0027
          37898881       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0027
          37898882       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0027
          37898883       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0032
          37898884       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898885       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898886       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898887       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0033
          37898888       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0003
          37898889       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0006
          37898890       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898891       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898892       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898893       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0004
          37898894       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898895       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898896       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898897       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0005
          37898898       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0007
          37898899       cpu trimgalo egarner9  RUNNING       0:07     30:00      1 p0010
          37898612       cpu ondemand egarner9  RUNNING      23:31   2:00:00      1 p0224
```

```bash
Mon Oct 20 10:38:28 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37898890       cpu trimgalo egarner9 COMPLETI       0:20     30:00      1 p0004
          37898891       cpu trimgalo egarner9 COMPLETI       0:21     30:00      1 p0004
          37898894       cpu trimgalo egarner9 COMPLETI       0:21     30:00      1 p0005
          37898881       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0027
          37898882       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0027
          37898883       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0032
          37898884       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0033
          37898885       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0033
          37898886       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0033
          37898887       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0033
          37898888       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0003
          37898889       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0006
          37898892       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0004
          37898893       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0004
          37898895       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0005
          37898896       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0005
          37898897       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0005
          37898898       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0007
          37898899       cpu trimgalo egarner9  RUNNING       0:21     30:00      1 p0010
          37898612       cpu ondemand egarner9  RUNNING      23:45   2:00:00      1 p0224
```

```bash
Mon Oct 20 10:38:46 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37898612       cpu ondemand egarner9  RUNNING      24:03   2:00:00      1 p0224
```


I used `-ls` to check that the slurm files were there:

```bash
data                           slurm-trimgalore-37898883.out  slurm-trimgalore-37898892.out
README.md                      slurm-trimgalore-37898884.out  slurm-trimgalore-37898893.out
results                        slurm-trimgalore-37898885.out  slurm-trimgalore-37898894.out
scripts                        slurm-trimgalore-37898886.out  slurm-trimgalore-37898895.out
slurm-trimgalore-37898878.out  slurm-trimgalore-37898887.out  slurm-trimgalore-37898896.out
slurm-trimgalore-37898879.out  slurm-trimgalore-37898888.out  slurm-trimgalore-37898897.out
slurm-trimgalore-37898880.out  slurm-trimgalore-37898889.out  slurm-trimgalore-37898898.out
slurm-trimgalore-37898881.out  slurm-trimgalore-37898890.out  slurm-trimgalore-37898899.out
slurm-trimgalore-37898882.out  slurm-trimgalore-37898891.out
```

I moved the slurm log files to results/logs by:  
`mkdir results/logs` then `mv slurm-trimgalore* results/logs`.

<br>

## Part D: 

15. Github repository created, and named GA4. Repository was pushed to the command line with:

```bash
git remote add origin git@github.com:egarner99/GA4.git
git branch -M main
git push -u origin main
```

I also did some final edits, redid the command for each time. 

16. Both @menukabh and @jelmerp were tagged in an issue once completed. 