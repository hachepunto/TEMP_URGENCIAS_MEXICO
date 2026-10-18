#!/bin/bash
# Paso 2 de la especificación H (H4): marginación para los códigos que pasan el FDR de calor.
# Lee codigos_fdr_2012_2025.csv (22). Un proceso por tercil de marginación k: primero D (MARG=k,
# todos los códigos con q < 0.05 a >= 36 °C, sin Z), luego E (CLIMA=1..3 con MARG=k, los 20 de
# mayor |beta_post| de calor). 3 procesos × 8 hilos.
cd /scratch/home/hachepunto/temp_urgencias/repo/analisis || exit 1
R=~/miniforge/envs/bio/bin/Rscript
LC_ALL=C.UTF-8 $R -e '
suppressMessages(library(data.table))
x <- fread("resultados/tablas/codigos_fdr_2012_2025.csv")[contraste == "calor_36" & sig & capitulo != "Z_control"]
setorder(x, -abs(beta_post))
writeLines(x$cie3, "logs/codigos_fdr_calor.txt"); writeLines(head(x$cie3, 20), "logs/codigos_fdr_calor_top20.txt")
cat("D:", nrow(x), "codigos; E: 20\n")' 2>&1 | grep -v setlocale
for k in 1 2 3; do
  (
    CONTEOS=codigos MARG=$k LC_ALL=C.UTF-8 NHILOS=8 $R 06_modelo_rezagos.R 2012_2025 $(cat logs/codigos_fdr_calor.txt) > "logs/06_codigos_marg${k}_2012_2025.log" 2>&1
    for j in 1 2 3; do
      CONTEOS=codigos CLIMA=$j MARG=$k LC_ALL=C.UTF-8 NHILOS=8 $R 06_modelo_rezagos.R 2012_2025 $(cat logs/codigos_fdr_calor_top20.txt) > "logs/06_codigos_clima${j}_marg${k}_2012_2025.log" 2>&1
    done
    echo "$(date) proceso marg$k terminado"
  ) &
done
wait
echo "$(date) paso 2 (D y E) terminado"
