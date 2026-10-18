#!/usr/bin/env Rscript
# Clima con ventanas de rezago hasta 30 días (0, 1-3, 4-7, 8-14, 15-21, 22-30), para la comparación
# con Sarmiento et al. (acumulado a 30 días). Misma construcción que en 05 (llave cve+fecha).
# Entrada: datos/derivados/clima_ventanas_2012_2025.parquet (bins del día) y los .rds de Tmax
# Salida:  datos/derivados/clima_ventanas30_2012_2025.parquet (desde 2012-01-31, para que las
#          ventanas de 30 días estén completas)
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025; cortes <- c(-Inf, seq(12, 36, by = 3), Inf)
dir_temp <- function(a) sprintf("/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL/%s",
                                ifelse(a <= 2022, "day_results", "day_results_v4r1"))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
m <- m[, .(municipio = ADM2_ES, state = ADM1_ES, cve = as.integer(sub("^MX", "", ADM2_PCODE)))]
tm <- rbindlist(lapply(c(min(anios) - 1, anios), function(a) {
  x <- as.data.table(readRDS(sprintf("%s/daymet_v4_daily_na_tmax_%d.rds", dir_temp(a), a)))
  x[, fecha := as.IDate(sprintf("%s-%02d-%02d", year, month, day))][, .(municipio, state, fecha, tmax = tmax_avg)]
}))
tm <- merge(tm, m, by = c("municipio", "state"))[, .(cve, fecha, bin = as.integer(cut(tmax, cortes, right = FALSE)))]
bis <- c(min(anios) - 1, anios)[c(min(anios) - 1, anios) %% 4 == 0]
d31 <- tm[fecha %in% as.IDate(sprintf("%d-12-30", bis))][, fecha := fecha + 1L]   # 31-dic bisiesto imputado
tm <- rbind(tm, d31); setkey(tm, cve, fecha)
for (k in 0:30) { lk <- tm[, .(cve, fecha = fecha + k, b = bin)]; tm[lk, (paste0("bin_l", k)) := i.b, on = .(cve, fecha)] }
base <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet",
                                   col_select = c("cve", "fecha", "tmax", "prcp", "bin", "bp")))
tm <- tm[fecha >= as.IDate("2012-01-31")]
ventanas <- list(v0 = 0L, v1_3 = 1:3, v4_7 = 4:7, v8_14 = 8:14, v15_21 = 15:21, v22_30 = 22:30)
nb <- length(cortes) - 1L
for (w in names(ventanas)) for (b in seq_len(nb)) {
  cols <- paste0("bin_l", ventanas[[w]])
  tm[, (sprintf("n_%s_b%d", w, b)) := Reduce(`+`, lapply(.SD, function(z) as.integer(z == b))), .SDcols = cols]
}
tm[, c("bin", paste0("bin_l", 0:30)) := NULL]
out <- merge(base, tm, by = c("cve", "fecha"))
stopifnot(!anyNA(out))
for (w in names(ventanas)) stopifnot(all(rowSums(out[, sprintf("n_%s_b%d", w, seq_len(nb)), with = FALSE]) == length(ventanas[[w]])))
write_parquet(out, "datos/derivados/clima_ventanas30_2012_2025.parquet")
message("clima_ventanas30: ", format(nrow(out), big.mark = ","), " filas, ", ncol(out), " columnas")
