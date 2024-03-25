#!/bin/bash
#SBATCH --job-name=north-sea_oysters_basic-exp
#SBATCH --ntasks=123
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=24G
#SBATCH --time=24:00:00
#SBATCH --partition=base

# make sure we have Singularity
module load gcc12-env/12.3.0 
module load singularity/3.11.5

# to get the image (need to be on a partition which has internet access --> data), run
# $ singularity pull --disable-cache --dir "${PWD}" docker://quay.io/willirath/parcels-container:2022.07.14-801fbe4

# make sure the output exists
mkdir -p notebooks_executed/revision

runtime_days=28
start_depth_meters=4
number_particles=10_000
RNG_seed=12345
for release_station in \
        DK_0044 FR_0206 FR_0172 FR_0073 FR_0090 FR_0015 FR_0083 IE_0982 \
        IE_0659 IE_0928 IE_1052 NL_0006 NL_0005 NW_0179 NW_0159 NW_0168 \
        UK_0022 UK_0018 UK_0013 UK_0036 UK_0052 UK_0074 UK_0014 UK_0012 \
        UK_0019 UK_0224 UK_0461 UK_0237 UK_0285 UK_0428 UK_0245 UK_0214; do
    for year in 2019 2020 2021 2022; do
        start_date_reference="${year}-05-01T00:00:00"
        for start_date_offset_days in {0..122}; do
            # run for single notebook and put into background
            srun --ntasks=1 --exclusive singularity run -B /sfs -B /gxfs_work -B $PWD:/work --pwd /work parcels-container_2022.07.14-801fbe4.sif bash -c \
            ". /opt/conda/etc/profile.d/conda.sh && conda activate base \
            && papermill --cwd notebooks/exploratory \
                notebooks/exploratory/2024-01-21_basic-experiment_revision.ipynb \
                notebooks_executed/revision/2024-01-21_basic-experiment_revision_${release_station}_RNG-seed-${RNG_seed}_start-date-reference-${start_date_reference}_start-date-offset-days-${start_date_offset_days}.ipynb \
                -p release_station ${release_station} \
                -p RNG_seed ${RNG_seed} \
                -p start_date_reference ${start_date_reference} \
                -p start_date_offset_days ${start_date_offset_days} \
                -p runtime_days ${runtime_days} \
                -p start_depth_meters ${start_depth_meters} \
                -p number_particles ${number_particles} \
                -k python" &
        done
    done
done

# wait till background task is done
wait

# print resource infos
jobinfo