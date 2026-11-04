#!/usr/bin/env Rscript
# Especificación L-a (ESPECIFICACION_aclimatacion_L.md): Tmax en bins por percentil local del municipio
# (percentiles de todos los días 2011-2025 de su propia serie), misma construcción de ventanas que 05/25.
# Entrada: .rds de tmax (day_results 2011-2022 / day_results_v4r1 2023-2025);
#          datos/derivados/clima_ventanas_2012_2025.parquet (para cve, fecha, tmax, prcp, bin, bp)
# Salida:  datos/derivados/clima_ventanas_rel_2012_2025.parquet, datos/derivados/tmax_percentiles_municipio.csv
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025
pcts  <- c(0.01, 0.05, 0.10, 0.25, 0.75, 0.90, 0.95, 0.975, 0.99)   # 10 bins; referencia = 5 ([25,75))
D <- "/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL"
dir_tmax <- function(a) sprintf("%s/%s", D, ifelse(a <= 2022, "day_results", "day_results_v4r1"))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
m <- m[, .(municipio = ADM2_ES, state = ADM1_ES, cve = as.integer(sub("^MX", "", ADM2_PCODE)))]
tm <- rbindlist(lapply(c(min(anios) - 1, anios), function(a) {
  x <- as.data.table(readRDS(sprintf("%s/daymet_v4_daily_na_tmax_%d.rds", dir_tmax(a), a)))
  x[, fecha := as.IDate(sprintf("%s-%02d-%02d", year, month, day))][, .(municipio, state, fecha, tmax = tmax_avg)]
}))
stopifnot(!anyNA(tm))
tm <- merge(tm, m, by = c("municipio", "state"))
stopifnot(uniqueN(tm$cve) == nrow(m))
# percentiles locales sobre los días observados (sin el 31-dic bisiesto imputado)
q <- tm[, as.list(quantile(tmax, pcts, names = FALSE)), by = cve]
setnames(q, c("cve", sprintf("p%s", sub("\\.", "_", as.character(100 * pcts)))))
fwrite(q, "datos/derivados/tmax_percentiles_municipio.csv")
message(sprintf("p99 local de Tmax: mediana %.1f °C (rango %.1f-%.1f); municipios con p99 < 36 °C: %d de %d",
                median(q$p99), min(q$p99), max(q$p99), sum(q$p99 < 36), nrow(q)))
tm <- merge(tm, q, by = "cve")
cc <- names(q)[-1]
tm[, bin := 1L + Reduce(`+`, lapply(cc, function(v) as.integer(tmax >= get(v))))]   # [p_k, p_k+1): cerrado abajo
tm <- tm[, .(cve, fecha, bin)]
print(tm[year(fecha) %in% anios, .(pct_dias = round(100 * .N / nrow(tm[year(fecha) %in% anios]), 2)), by = bin][order(bin)])
bis <- c(min(anios) - 1, anios)[c(min(anios) - 1, anios) %% 4 == 0]
d31 <- tm[fecha %in% as.IDate(sprintf("%d-12-30", bis))][, fecha := fecha + 1L]   # 31-dic bisiesto imputado, como en 05/25
tm <- rbind(tm, d31); setkey(tm, cve, fecha)
base <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet",
                                   col_select = c("cve", "fecha", "tmax", "prcp", "bin", "bp")))
setnames(base, "bin", "bin_abs")
ventanas <- list(v0 = 0L, v1_3 = 1:3, v4_7 = 4:7, v8_14 = 8:14); nb <- length(pcts) + 1L
x <- copy(tm)
for (k in 0:14) { lk <- x[, .(cve, fecha = fecha + k, b = bin)]; x[lk, (paste0("bin_l", k)) := i.b, on = .(cve, fecha)] }
for (w in names(ventanas)) for (bb in seq_len(nb)) {
  cols <- paste0("bin_l", ventanas[[w]])
  x[, (sprintf("n_%s_b%d", w, bb)) := Reduce(`+`, lapply(.SD, function(z) as.integer(z == bb))), .SDcols = cols]
}
x[, c(paste0("bin_l", 0:14)) := NULL]
out <- merge(base, x, by = c("cve", "fecha"))
stopifnot(!anyNA(out), nrow(out) == nrow(base))
for (w in names(ventanas)) stopifnot(all(rowSums(out[, sprintf("n_%s_b%d", w, seq_len(nb)), with = FALSE]) == length(ventanas[[w]])))
print(out[, .(dias_abs36 = sum(bin_abs == 10L), dias_p99 = sum(bin == nb), mun_p99 = uniqueN(cve[bin == nb]), mun_abs36 = uniqueN(cve[bin_abs == 10L]))])
out[, bin_abs := NULL]
write_parquet(out, "datos/derivados/clima_ventanas_rel_2012_2025.parquet")
message("-> clima_ventanas_rel_2012_2025.parquet: ", format(nrow(out), big.mark = ","), " filas, ", ncol(out), " columnas")
