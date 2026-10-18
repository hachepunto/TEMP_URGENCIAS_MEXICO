#!/usr/bin/env Rscript
# Lee las defunciones registradas (INEGI, redistribuidas por la DGIS) 2012-2024 y deja una tabla
# compacta por defunción: fecha de ocurrencia, entidad y municipio de residencia, causa CIE-10 (3 car.).
# Especificación G. El formato cambia por año (nombres en mayúsculas en 2012-13; campos con tabuladores
# en 2016; columnas extra desde 2023), por eso se normalizan nombres y se recorta todo.
# Entrada: /STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DEFUNCIONES_DGIS/DEFUN_*.zip
# Salida:  datos/derivados/defunciones_2012_2024.parquet
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
dir_z <- "/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DEFUNCIONES_DGIS"
zips  <- list.files(dir_z, "^DEFUN_.*\\.zip$", full.names = TRUE)
quiero <- c("ent_resid", "mun_resid", "causa_def", "dia_ocurr", "mes_ocurr", "anio_ocur")

leer_csv <- function(z, m) {
  d <- fread(cmd = sprintf("unzip -p '%s' '%s'", z, m), colClasses = "character", encoding = "Latin-1")
  setnames(d, tolower(trimws(sub("^﻿", "", names(d)))))
  stopifnot(all(quiero %in% names(d)))
  d <- d[, ..quiero]
  for (v in quiero) set(d, j = v, value = trimws(d[[v]]))
  d[, `:=`(ent_res = as.integer(ent_resid), mun_res = as.integer(mun_resid), cie3 = substr(toupper(causa_def), 1, 3),
           fecha = suppressWarnings(as.IDate(sprintf("%s-%02d-%02d", anio_ocur, as.integer(mes_ocurr), as.integer(dia_ocurr)))))]
  d[, .(fecha, ent_res, mun_res, cie3, archivo = basename(m))]
}
res <- rbindlist(lapply(zips, function(z) {
  ms <- grep("\\.csv$", unzip(z, list = TRUE)$Name, ignore.case = TRUE, value = TRUE)
  ms <- ms[!grepl("catalog|diccionario|modelo", ms, ignore.case = TRUE)]
  rbindlist(lapply(ms, function(m) leer_csv(z, m)))
}))
# validación por archivo: fecha válida, residencia, cardinalidad de municipios (mismo chequeo que urgencias)
val <- res[, .(n = .N, pct_fecha_na = round(100 * mean(is.na(fecha)), 2),
               pct_mun_na = round(100 * mean(is.na(mun_res) | mun_res >= 998), 2),
               pct_mun_igual_ent = round(100 * mean(mun_res == ent_res, na.rm = TRUE), 2),
               municipios = uniqueN((ent_res * 1000L + mun_res)[mun_res < 998]),
               anio_min = min(year(fecha), na.rm = TRUE), anio_max = max(year(fecha), na.rm = TRUE)), by = archivo]
print(val)
stopifnot(all(val$pct_mun_igual_ent < 10), all(val$municipios > 1500))
res[mun_res >= 998L, mun_res := NA_integer_]
res <- res[!is.na(fecha) & fecha >= as.IDate("2012-01-01") & fecha <= as.IDate("2024-12-31")]
write_parquet(res[, .(fecha, ent_res, mun_res, cie3)], "datos/derivados/defunciones_2012_2024.parquet")
message("defunciones 2012-2024: ", format(nrow(res), big.mark = ","), " registros con fecha de ocurrencia en el periodo")
