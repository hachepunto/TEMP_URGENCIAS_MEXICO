#!/bin/bash
# Rehace todos los resultados de urgencias con el panel corregido (sin 2012-12-26..2013-12-25) y las partes
# pendientes de la especificación G (AUDITORIA_2026-10-18). El principal, la sensibilidad A y la mortalidad
# ya se rehicieron aparte. Los resultados anteriores están congelados en
# resultados/historico/2026-10-18_hueco2013_defun/.
# Fase 1: cola de corridas independientes, 3 procesos × 8 hilos (otro job propio usa ~30 cores; tope 55).
# Fase 2: lo que depende del barrido por código (22, 23, marginación por código, 24) y comparaciones (26).
export OPENBLAS_NUM_THREADS=1   # límite de hilos de BLAS (no OMP_NUM_THREADS: data.table y fixest lo toman como tope) (aviso de uso de cores 2026-10-18)
cd /scratch/home/hachepunto/temp_urgencias/repo/analisis || exit 1
export LC_ALL=C.UTF-8 NHILOS=8
R=~/miniforge/envs/bio/bin/Rscript
T=resultados/tablas
# se borran los directorios por desenlace que se van a rehacer, para que no sobrevivan archivos viejos
rm -rf $T/rezagos_subgrupos $T/rezagos_marg? $T/rezagos_clima?_marg? $T/rezagos_hospital $T/rezagos_v30 \
       $T/rezagos_desde2014 $T/rezagos_expo-at $T/rezagos_expo-hum $T/rezagos_codigos $T/rezagos_codigos_* \
       $T/rezagos_defunciones_marg?
E5="infecciosas endocrinas genitourinario traumatismos total"
COLA=logs/cola_rehacer.txt
{
  echo "CONTEOS=subgrupos|06_subgrupos"
  for k in 1 2 3; do echo "MARG=$k|06_marg$k"; done
  for j in 1 2 3; do for k in 1 2 3; do echo "CLIMA=$j MARG=$k|06_clima${j}_marg$k|$E5"; done; done
  echo "CONTEOS=hospital|06_hospital"
  echo "VENTANAS=30|06_v30|circulatorio infecciosas nervioso respiratorio total"
  echo "ANIO_MIN=2014|06_desde2014"
  echo "EXPO=at|06_expo-at"
  echo "EXPO=hum|06_expo-hum"
  awk -F, 'NR>1{print $1}' datos/derivados/codigos_incluidos.csv > logs/codigos_todos.txt
  [ "$(wc -l < logs/codigos_todos.txt)" -eq 164 ] || { echo "lista de códigos incompleta" >&2; exit 1; }
  split -n l/6 -d logs/codigos_todos.txt logs/lote_rehacer_
  for k in 0 1 2 3 4 5; do echo "CONTEOS=codigos|06_codigos_lote$k|$(paste -sd' ' logs/lote_rehacer_0$k)"; done
  for k in 1 2 3; do echo "CONTEOS=defunciones MARG=$k|06_defunciones_marg$k"; done
} > $COLA || exit 1
echo "$(date) fase 1: $(wc -l < $COLA) corridas"
correr() {   # $1 = "VARS|log|args"
  IFS='|' read -r vars log args <<< "$1"
  env $vars $R 06_modelo_rezagos.R 2012_2025 $args > "logs/${log}_2012_2025.log" 2>&1 && echo "OK $log" || echo "FALLO $log"
}
export -f correr; export R
xargs -P 3 -d '\n' -I{} bash -c 'correr "$@"' _ {} < $COLA
echo "$(date) fase 1 terminada"

# --- fase 2 ---
$R 22_codigos_fdr.R > logs/22_codigos_fdr.log 2>&1 && echo "OK 22" || echo "FALLO 22"
$R 23_figura_codigos.R > logs/23_figura_codigos.log 2>&1 && echo "OK 23" || echo "FALLO 23"
logs/lanzar_codigos_marginacion.sh > logs/lanzar_codigos_marginacion.log 2>&1 && echo "OK marginación por código" || echo "FALLO marginación por código"
EXPO=hum CONTEOS=codigos $R 06_modelo_rezagos.R 2012_2025 E86 A09 A90 A97 T63 N23 > logs/06_codigos_expo-hum_2012_2025.log 2>&1 && echo "OK códigos hum" || echo "FALLO códigos hum"
$R 24_codigos_marginacion.R > logs/24_codigos_marginacion.log 2>&1 && echo "OK 24" || echo "FALLO 24"
$R 26_humedad_comparacion.R > logs/26_humedad_comparacion.log 2>&1 && echo "OK 26" || echo "FALLO 26"
echo "$(date) fase 2 terminada"
