#!/bin/bash
# Extracción municipal de presión de vapor (vp) Daymet V4R1 2011-2025 con 00_clima_municipal.R,
# 3 archivos a la vez (terra es monohilo; ~8 min y ~16 GB por archivo).
export OPENBLAS_NUM_THREADS=1   # límite de hilos de BLAS (no OMP_NUM_THREADS: data.table y fixest lo toman como tope) (aviso de uso de cores 2026-10-18)
cd /scratch/home/hachepunto/temp_urgencias/repo/analisis || exit 1
export LC_ALL=C.UTF-8 GDAL_DRIVER_PATH=$HOME/miniforge/envs/bio/lib/gdalplugins PROJ_DATA=$HOME/miniforge/envs/bio/share/proj
D=/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL
ls $D/diaria_daymet_v4r1/daymet_v4_daily_na_vp_*.nc | xargs -P 3 -I{} sh -c \
  '~/miniforge/envs/bio/bin/Rscript 00_clima_municipal.R {} '"$D"'/day_results_v4r1 > logs/00_$(basename {} .nc).log 2>&1 && echo OK {} || echo FALLO {}'
echo "$(date) vp terminado"; ls -la $D/day_results_v4r1/*vp*
