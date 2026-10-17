#!/usr/bin/env Rscript
# Cobertura por institución (ESPECIFICACION_sensibilidad_subgrupos.md, sección C):
# atenciones por año × institución (letras 3-5 de la CLUES) y por estado × año × institución.
# Entrada: datos/derivados/urgencias_2012_2025.parquet
# Salida:  resultados/tablas/cobertura_institucion_anio.csv, cobertura_estado_anio.csv
suppressMessages({library(data.table); library(arrow)})
setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
u <- as.data.table(read_parquet("datos/derivados/urgencias_2012_2025.parquet", col_select = c("anio", "clues")))
u[, `:=`(ent_clues = substr(clues, 1, 2), inst = substr(clues, 3, 5))]
a <- u[, .N, by = .(anio, inst)][order(anio, -N)]
a[, pct := round(100 * N / sum(N), 2), by = anio]
fwrite(a, "resultados/tablas/cobertura_institucion_anio.csv")
e <- u[, .N, by = .(ent_clues, anio)][order(ent_clues, anio)]
e[, idx_2019 := round(N / N[anio == 2019], 3), by = ent_clues]   # volumen relativo a 2019
e_imb <- u[inst == "IMB", .(N_imb = .N), by = .(ent_clues, anio)]
e <- merge(e, e_imb, by = c("ent_clues", "anio"), all.x = TRUE)[is.na(N_imb), N_imb := 0L]
e[, pct_imb := round(100 * N_imb / N, 1)]
fwrite(e, "resultados/tablas/cobertura_estado_anio.csv")
print(dcast(a[inst %in% c("SSA", "IMB", "IMS", "IST") | pct > 1], anio ~ inst, value.var = "pct", fill = 0))
cat("\nEstados con >= 20 % IMB en 2024-2025 y su volumen relativo a 2019:\n")
print(e[anio >= 2023 & pct_imb >= 20, .(ent_clues, anio, N, idx_2019, pct_imb)][order(ent_clues, anio)])
