#!/usr/bin/env Rscript
# Lee las bases crudas de urgencias DGIS 2012-2022 y deja una tabla compacta
# (una fila por atención) con fecha de ingreso, municipio de residencia,
# CLUES y diagnóstico principal.
# 2010-2011 se omiten: no traen MUNRESIDENCIA.

suppressMessages({library(data.table); library(arrow)})
setDTthreads(16)

dir_crudos <- "/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DATOS_URGENCIAS"
salida     <- "datos/derivados/urgencias_2012_2022.parquet"
dir.create(dirname(salida), recursive = TRUE, showWarnings = FALSE)

archivos <- list.files(dir_crudos, "^URGENCIAS_20(1[2-9]|2[0-2])\\.", full.names = TRUE)

leer_anio <- function(f) {
  anio <- as.integer(sub(".*URGENCIAS_(\\d{4}).*", "\\1", f))
  # separador según el encabezado; las líneas con otro número de campos
  # (pies "(n row(s) affected)", líneas truncadas) se descartan con awk
  l1  <- readLines(f, n = 1, warn = FALSE)
  n_sep <- sapply(c(";", "|", ","), function(s) lengths(regmatches(l1, gregexpr(s, l1, fixed = TRUE))))
  sep <- names(which.max(n_sep))
  # NF del encabezado contado con el mismo awk que filtra las líneas
  nf  <- as.integer(system(sprintf("head -1 '%s' | LC_ALL=C awk -F'%s' '{print NF}'", f, sep), intern = TRUE))
  # además se descartan líneas con bytes fuera de ASCII imprimible (55 en 2015, 13 en 2018: basura)
  cmd <- sprintf("LC_ALL=C awk -F'%s' 'NR==1 || (NF==%d && !/[^\\t\\r -~]/)' '%s'", sep, nf, f)
  n_lineas <- as.numeric(system(sprintf("wc -l < '%s'", f), intern = TRUE))
  cab  <- names(fread(cmd = cmd, nrows = 0, sep = sep))
  cab_up <- toupper(sub("^﻿", "", cab))
  # el nombre de la columna de fecha de ingreso cambia entre años
  col_fecha <- cab[match(TRUE, cab_up %in% c("FECHAINGRESO", "FECHAINGRE"))]
  quiero <- c(CLUES = "CLUES", ENTRESIDENCIA = "ENTRESIDENCIA",
              MUNRESIDENCIA = "MUNRESIDENCIA", AFECPRIN = "AFECPRIN")
  cols <- c(cab[match(quiero, cab_up)], col_fecha)
  d <- fread(cmd = cmd, sep = sep, select = cols, colClasses = "character",
             na.strings = c("", "NULL"))
  descartadas <- n_lineas - 1 - nrow(d)
  setnames(d, c(names(quiero), "FECHA"))
  d[, `:=`(
    anio    = anio,
    fecha   = as.IDate(substr(trimws(FECHA), 1, 10)),
    ent_res = as.integer(ENTRESIDENCIA),
    mun_res = as.integer(MUNRESIDENCIA),
    cie3    = substr(toupper(trimws(AFECPRIN)), 1, 3)
  )]
  n0 <- nrow(d)
  res <- d[, .(anio, fecha, ent_res, mun_res, clues = trimws(CLUES), cie3)]
  message(sprintf("%d: %s filas (descartadas %s) | fecha NA %.2f%% | ent_res fuera 1-32 %.2f%% | mun_res 999/NA %.2f%% | fecha fuera del año %.2f%%",
                  anio, format(n0, big.mark = ","), format(descartadas, big.mark = ","),
                  100 * mean(is.na(res$fecha)),
                  100 * mean(!res$ent_res %in% 1:32),
                  100 * mean(is.na(res$mun_res) | res$mun_res >= 999),
                  100 * mean(year(res$fecha) != anio, na.rm = TRUE)))
  res
}

u <- rbindlist(lapply(archivos, leer_anio))
write_parquet(u, salida)
message("total: ", format(nrow(u), big.mark = ","), " filas -> ", salida)
