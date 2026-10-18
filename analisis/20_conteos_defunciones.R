#!/usr/bin/env Rscript
# Conteos diarios de defunciones por municipio de residencia para los desenlaces de la especificación G:
# todas las causas, naturales (A00-R99), circulatorio (I), respiratorio (J), renal (N17-N19),
# endocrino (E), causas externas (V01-Y98). Golpe de calor (X30, T67) sólo se cuenta para el descriptivo.
# Entrada: datos/derivados/defunciones_2012_2024.parquet (19)
# Salida:  datos/derivados/conteos_defunciones_2012_2025.parquet (cve, fecha, cap, casos; sin ceros;
#          el nombre lleva el periodo del clima para que 06 lo encuentre; 2025 no tiene defunciones)
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
d <- as.data.table(read_parquet("datos/derivados/defunciones_2012_2024.parquet"))
d <- d[ent_res %in% 1:32 & !is.na(mun_res)]
d[, cve := ent_res * 1000L + mun_res]
message(sprintf("defunciones con residencia válida: %s; sin polígono: %.2f%%", format(nrow(d), big.mark = ","), 100 * mean(!d$cve %in% cves)))
d <- d[cve %in% cves]
llave <- function(x) match(substr(x, 1, 1), LETTERS) * 100L + suppressWarnings(as.integer(substr(x, 2, 3)))
d[, k := llave(cie3)]
rangos <- list(
  todas        = c(llave("A00"), llave("Z99")),
  naturales    = c(llave("A00"), llave("R99")),
  circulatorio = c(llave("I00"), llave("I99")),
  respiratorio = c(llave("J00"), llave("J99")),
  renal        = c(llave("N17"), llave("N19")),
  endocrino    = c(llave("E00"), llave("E90")),
  externas     = c(llave("V01"), llave("Y98")))
conteos <- rbindlist(lapply(names(rangos), function(nm) {
  r <- rangos[[nm]]; d[k >= r[1] & k <= r[2], .(casos = .N), by = .(cve, fecha)][, cap := nm]
}))
calor <- d[cie3 %in% c("X30", "T67"), .N, by = year(fecha)][order(year)]
message("golpe de calor (X30/T67) por año: ", paste(sprintf("%d:%d", calor$year, calor$N), collapse = " "))
print(conteos[, .(casos = sum(casos), filas = .N), by = cap])
write_parquet(conteos[, .(cve, fecha, cap, casos)], "datos/derivados/conteos_defunciones_2012_2025.parquet")
message("-> conteos_defunciones_2012_2025.parquet")
