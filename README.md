This pipeline processes barcode count data from MPRA experiments (tk subassembly association).

Installation

Required software
- conda

Clone repository

        cd /home/UNIQNAME/github
        git clone https://github.com/mpraline.git


Set up environment/install required packages

        cd mpraline
        conda env create -n bc_count -f bc_count.yml

Steps to run the pipeline

        conda activate bc_count

1. Create an output project directory.
2. In the subdirectory `sampletab`, create a sample metadata table containing the variables `libname`, `fq_fwd`, `fq_rev`, and `umi_len`. 
If your sample names are in sample##_{RNA, DNA} format, you can use the following code to complete required columns `fq_fwd`, `fq_rev`, and `umi_len`.

       pfx=YYYYMMDD

       touch sampletab/${pfx}.txt

       cd in_fq

       prefixes=$(ls *.r[1,2].fq.gz | cut -d. -f1 | sort -u)

       echo "libname" >> ../sampletab/${pfx}.txt

       for prefix in $prefixes; do
           echo "$prefix" >> ../sampletab/${pfx}.txt
       done

       cd ..

       muchly addcol \
           -i sampletab/${pfx}.txt \
           -o sampletab/${pfx}.2.txt \
           -t \
           "fq_fwd:/full/path/to/project/in_fq/{{libname}}.r1.fq.gz" \
           "fq_rev:/full/path/to/project/in_fq/{{libname}}.r2.fq.gz"

        cat sampletab/${pfx}.2.txt | mlr --tsv put '$umi_len = (sub($libname, "^[^_]+_(DNA)$", "13") == "13") ? "13" : ""' > sampletab/${pfx}.input.txt

2. Load R (currently tested with R/4.2.0). Check that your $PATH lists the bin associated with the conda environment first (i.e., `PATH=/home/user/miniconda3/envs/mpraline/bin:$PATH`). If not, make it so or else none of the packages you've installed will work when python is invoked.
3. If you don't have a server profile (`slurmgl`) created for snakemake, create one with the following command:

        mkdir slurmgl
        echo """\
        jobs: 1000
        cluster: "sbatch --account=INSERT_ACCOUNT --time={resources.time} --mem-per-cpu={resources.mem_per_cpu} --cpus-per-task={resources.cpus} --nodes=1 -o logs_slurm/{rule}_{wildcards} -e logs_slurm/{rule}_{wildcards}"\
        """ > slurmgl/config.yaml

Make sure to change `INSERT_ACCOUNT` with the correct server billing account or remove if unnecessary.

4. Run the pipeline with the following command:

        snakemake -s /path/to/bc_count.snake \
            --printshellcmds \
            --cores 32 \
            --jobs 1000 --rerun-incomplete \
            --restart-times 3 \
            --force \
            --profile slurmgl \
            --printshellcmds \
            --max-jobs-per-second 5 \
            --max-status-checks-per-second 5 \
            --latency-wait 150 --wait-for-files \
            --config \
                sample_table=sampletab/${pfx}.input.txt \
                outdir=bc_count \
                scripts=/path/to/scripts

If you want to run the pipeline in the background (so you can sign out and have it run in the background), prefix with `nohup` and append with `&`. If you need to rerun the pipeline, you will need to unlock the directory with the flag `--unlock`, then re-run. 

4. Once the pipeline completes, `done.txt` will be created in the top directory.
