#!/bin/bash
# Especificación J: 7 corridas, 3 a la vez × 8 hilos.
export OPENBLAS_NUM_THREADS=1   # límite de hilos de BLAS (no OMP_NUM_THREADS: data.table y fixest lo toman como tope) (aviso de uso de cores 2026-10-18)
cd /scratch/home/hachepunto/temp_urgencias/repo/analisis || exit 1
export LC_ALL=C.UTF-8 NHILOS=8 R=~/miniforge/envs/bio/bin/Rscript
correr() { IFS='|' read -r vars log args <<< "$1"; env $vars $R 06_modelo_rezagos.R 2012_2025 $args > "logs/${log}_2012_2025.log" 2>&1 && echo "OK $log" || echo "FALLO $log"; }
export -f correr
xargs -P 3 -d '\n' -I{} bash -c 'correr "$@"' _ {} < logs/cola_J.txt
echo "$(date) J terminado"
