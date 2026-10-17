#!/usr/bin/env Rscript
# Clima de base por municipio (ESPECIFICACION_sensibilidad_subgrupos.md, E): fracción de días
# 2012-2025 con Tmax >= 33 °C (bins 9 y 10), terciles por número de municipios (C1 templado … C3 cálido),
# y tamaño de las 9 celdas clima × marginación.
# Entrada: datos/derivados/clima_ventanas_2012_2025.parquet, marginacion_terciles_2020.csv
# Salida:  datos/derivados/clima_base_terciles.csv (cve, frac_ge33, clima); resultados/tablas/celdas_clima_marg.csv
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet", col_select = c("cve", "bin")))
b <- cl[, .(frac_ge33 = mean(bin >= 9), dias_33_36 = sum(bin == 9), dias_ge36 = sum(bin == 10)), by = cve]
b[, clima := cut(frac_ge33, quantile(frac_ge33, c(0, 1/3, 2/3, 1)), labels = 1:3, include.lowest = TRUE)]
print(b[, .(n = .N, frac_min = round(min(frac_ge33), 3), frac_max = round(max(frac_ge33), 3)), by = clima][order(clima)])
m <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)]
b <- merge(b, m, by = "cve")
celdas <- b[, .(municipios = .N, dias_33_36 = sum(dias_33_36), dias_ge36 = sum(dias_ge36),
                mun_con_ge36 = sum(dias_ge36 > 0)), by = .(clima, marg)][order(clima, marg)]
celdas[, ge36_identificado := dias_ge36 >= 2000 & mun_con_ge36 >= 50]
print(celdas)
fwrite(b[, .(cve, frac_ge33, clima, marg)], "datos/derivados/clima_base_terciles.csv")
fwrite(celdas, "resultados/tablas/celdas_clima_marg.csv")
