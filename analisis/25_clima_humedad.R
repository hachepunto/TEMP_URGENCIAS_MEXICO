#!/usr/bin/env Rscript
# Especificación I: exposiciones alternativas con humedad (vp Daymet V4R1), misma construcción que 05/05b.
#  at : temperatura aparente de Steadman AT = Tmax + 0.33*e(hPa) - 4, mismos cortes de 3 °C.
#  hum: Tmax en los mismos bins, con [33,36) y [36,Inf) partidos por punto de rocío (Td >= 15 °C = húmedo).
# Entrada: .rds de tmax (day_results / day_results_v4r1) y de vp (day_results_v4r1), 2011-2025;
#          datos/derivados/clima_ventanas_2012_2025.parquet (para cve, fecha, tmax, prcp, bin, bp)
# Salida:  datos/derivados/clima_ventanas_at_2012_2025.parquet, clima_ventanas_hum_2012_2025.parquet
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025; cortes <- c(-Inf, seq(12, 36, by = 3), Inf); td_corte <- 15
D <- "/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL"
dir_tmax <- function(a) sprintf("%s/%s", D, ifelse(a <= 2022, "day_results", "day_results_v4r1"))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
m <- m[, .(municipio = ADM2_ES, state = ADM1_ES, cve = as.integer(sub("^MX", "", ADM2_PCODE)))]
tm <- rbindlist(lapply(c(min(anios) - 1, anios), function(a) {
  x <- as.data.table(readRDS(sprintf("%s/daymet_v4_daily_na_tmax_%d.rds", dir_tmax(a), a)))
  v <- as.data.table(readRDS(sprintf("%s/day_results_v4r1/daymet_v4_daily_na_vp_%d.rds", D, a)))
  x <- merge(x, v[, .(municipio, state, year, month, day, vp = vp_avg)], by = c("municipio", "state", "year", "month", "day"))
  x[, fecha := as.IDate(sprintf("%s-%02d-%02d", year, month, day))][, .(municipio, state, fecha, tmax = tmax_avg, vp)]
}))
stopifnot(!anyNA(tm))
tm <- merge(tm, m, by = c("municipio", "state"))
tm[, at := tmax + 0.33 * vp / 100 - 4]
tm[, td := 243.04 * log(vp / 610.94) / (17.625 - log(vp / 610.94))]
message(sprintf("AT - Tmax: mediana %.1f, p90 %.1f °C; días Tmax>=36 húmedos (Td>=%d): %.1f%%",
                median(tm$at - tm$tmax), quantile(tm$at - tm$tmax, .9), td_corte, 100 * tm[tmax >= 36, mean(td >= td_corte)]))
tm[, bin_at := as.integer(cut(at, cortes, right = FALSE))]
b <- as.integer(cut(tm$tmax, cortes, right = FALSE))   # 1..10; 9 = [33,36), 10 = [36,Inf)
hum <- as.integer(tm$td >= td_corte)
tm[, bin_hum := fifelse(b <= 8L, b, 9L + 2L * (b - 9L) + hum)]   # 9/10 = [33,36) seco/húmedo, 11/12 = [36,Inf) seco/húmedo
tm <- tm[, .(cve, fecha, bin_at, bin_hum)]
bis <- c(min(anios) - 1, anios)[c(min(anios) - 1, anios) %% 4 == 0]
d31 <- tm[fecha %in% as.IDate(sprintf("%d-12-30", bis))][, fecha := fecha + 1L]   # 31-dic bisiesto imputado
tm <- rbind(tm, d31); setkey(tm, cve, fecha)
base <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet",
                                   col_select = c("cve", "fecha", "tmax", "prcp", "bin", "bp")))
ventanas <- list(v0 = 0L, v1_3 = 1:3, v4_7 = 4:7, v8_14 = 8:14)
construir <- function(col, nb, salida) {
  x <- tm[, c("cve", "fecha", col), with = FALSE]; setnames(x, col, "bin")
  for (k in 0:14) { lk <- x[, .(cve, fecha = fecha + k, b = bin)]; x[lk, (paste0("bin_l", k)) := i.b, on = .(cve, fecha)] }
  for (w in names(ventanas)) for (bb in seq_len(nb)) {
    cols <- paste0("bin_l", ventanas[[w]])
    x[, (sprintf("n_%s_b%d", w, bb)) := Reduce(`+`, lapply(.SD, function(z) as.integer(z == bb))), .SDcols = cols]
  }
  x[, c("bin", paste0("bin_l", 0:14)) := NULL]
  out <- merge(base, x, by = c("cve", "fecha"))
  stopifnot(!anyNA(out), nrow(out) == nrow(base))
  for (w in names(ventanas)) stopifnot(all(rowSums(out[, sprintf("n_%s_b%d", w, seq_len(nb)), with = FALSE]) == length(ventanas[[w]])))
  write_parquet(out, salida); message("-> ", salida, ": ", format(nrow(out), big.mark = ","), " filas, ", ncol(out), " columnas")
}
construir("bin_at", 10L, "datos/derivados/clima_ventanas_at_2012_2025.parquet")
construir("bin_hum", 12L, "datos/derivados/clima_ventanas_hum_2012_2025.parquet")
