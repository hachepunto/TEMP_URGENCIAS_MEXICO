#!/bin/bash
# Espera a que terminen los lotes 0 y 1 del barrido por código (PIDs dados) y lanza en dos lotes
# los códigos comprometidos que aún no tienen resultado. Existe porque el tope de CPU del nodo
# (55 hilos propios) obligó a detener los lotes 2 y 3 mientras corre otro job propio (mra_bench).
export OPENBLAS_NUM_THREADS=1   # límite de hilos de BLAS (no OMP_NUM_THREADS: data.table y fixest lo toman como tope) (aviso de uso de cores 2026-10-18)
cd /scratch/home/hachepunto/temp_urgencias/repo/analisis || exit 1
while kill -0 1029818 2>/dev/null || kill -0 1029822 2>/dev/null; do sleep 60; done
awk -F, 'NR>1{print $1}' datos/derivados/codigos_incluidos.csv | while read -r c; do
  [ -f "resultados/tablas/rezagos_codigos/2012_2025_${c}_resumen.csv" ] || echo "$c"
done > logs/codigos_pendientes2.txt
n=$(wc -l < logs/codigos_pendientes2.txt); echo "$(date) pendientes: $n"
[ "$n" -ge 2 ] || { echo "menos de 2 pendientes ($n): correr a mano; un lote vacío haría correr los 164"; exit 1; }   # AUDITORIA_2026-10-18, I3
split -n l/2 -d logs/codigos_pendientes2.txt logs/lote2_codigos_
for k in 0 1; do
  CONTEOS=codigos LC_ALL=C.UTF-8 NHILOS=8 nohup ~/miniforge/envs/bio/bin/Rscript 06_modelo_rezagos.R 2012_2025 $(cat "logs/lote2_codigos_0$k") > "logs/06_codigos_lote2-${k}_2012_2025.log" 2>&1 &
done
wait
echo "$(date) lotes 2-0 y 2-1 terminados"
