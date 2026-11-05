#!/usr/bin/env Rscript
# Especificación L-a2 (ESPECIFICACION_dosis_L-a2.md): Tmax absoluta con los cortes de 05 y el bin >= 36 partido
# en [36,38), [38,40), [40,Inf); misma construcción de ventanas que 05/25/33.
# Entrada: .rds de tmax (day_results 2011-2022 / day_results_v4r1 2023-2025);
#          datos/derivados/clima_ventanas_2012_2025.parquet (para cve, fecha, tmax, prcp, bin, bp)
# Salida:  datos/derivados/clima_ventanas_fino_2012_2025.parquet
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025
cortes <- c(-Inf, seq(12, 36, by = 3), 38, 40, Inf)   # 12 bins; referencia [24,27) = 5
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
tm[, bin := as.integer(cut(tmax, cortes, right = FALSE))]
tm <- tm[, .(cve, fecha, bin)]
bis <- c(min(anios) - 1, anios)[c(min(anios) - 1, anios) %% 4 == 0]
d31 <- tm[fecha %in% as.IDate(sprintf("%d-12-30", bis))][, fecha := fecha + 1L]   # 31-dic bisiesto imputado, como en 05/25
tm <- rbind(tm, d31); setkey(tm, cve, fecha)
base <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet",
                                   col_select = c("cve", "fecha", "tmax", "prcp", "bin", "bp")))
setnames(base, "bin", "bin_abs")
ventanas <- list(v0 = 0L, v1_3 = 1:3, v4_7 = 4:7, v8_14 = 8:14); nb <- length(cortes) - 1L
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
# coherencia con 05: bins 1-9 idénticos y 10-12 = [36,Inf)
stopifnot(all(out[, pmin(bin, 10L) == bin_abs]))
print(out[bin >= 10L, .(dias = .N, municipios = uniqueN(cve)), by = bin][order(bin)])
out[, bin_abs := NULL]
write_parquet(out, "datos/derivados/clima_ventanas_fino_2012_2025.parquet")
message("-> clima_ventanas_fino_2012_2025.parquet: ", format(nrow(out), big.mark = ","), " filas, ", ncol(out), " columnas")
