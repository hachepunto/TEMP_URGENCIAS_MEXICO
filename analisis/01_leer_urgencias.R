#!/usr/bin/env Rscript
# Lee las bases crudas de urgencias DGIS 2012-2025 y deja una tabla compacta
# (una fila por atención) con fecha de ingreso, municipio de residencia,
# CLUES y diagnóstico principal.
# 2010-2011 se omiten: no traen MUNRESIDENCIA.
# 2013 se excluye: en el archivo de la DGIS (también en el zip vigente, verificado 2026-10-17)
# MUNRESIDENCIA es una copia de ENTRESIDENCIA con cero a la izquierda en el 100 % de las filas,
# así que no identifica el municipio. Diciembre de 2013 sí entra (viene del archivo 2014).
# Cada año pasa una validación de contenido: % de mun_res == ent_res y número de municipios.

suppressMessages({library(data.table); library(arrow)})
setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))

dir_crudos <- "/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DATOS_URGENCIAS"
salida     <- "datos/derivados/urgencias_2012_2025.parquet"
dir.create(dirname(salida), recursive = TRUE, showWarnings = FALSE)

anios_excluidos <- c(2013)
archivos <- list.files(dir_crudos, "^URGENCIAS_20(1[2-9]|2[0-5])\\.", full.names = TRUE)
archivos <- archivos[!as.integer(sub(".*URGENCIAS_(\\d{4}).*", "\\1", archivos)) %in% anios_excluidos]

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
  n_lineas <- as.numeric(system(sprintf("LC_ALL=C awk 'END{print NR}' '%s'", f), intern = TRUE))  # NR cuenta también una última línea sin \n
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
    mun_res = as.integer(MUNRESIDENCIA),   # 998 y 999 = no especificado (se tratan igual abajo)
    cie3    = substr(toupper(trimws(AFECPRIN)), 1, 3)
  )]
  d[mun_res >= 998L, mun_res := NA_integer_]
  n0 <- nrow(d)
  res <- d[, .(anio, fecha, ent_res, mun_res, clues = trimws(CLUES), cie3)]
  # validación de contenido de MUNRESIDENCIA (error 2013: mun_res == ent_res en el 100 %)
  v <- res[ent_res %in% 1:32 & !is.na(mun_res)]
  pct_igual <- 100 * mean(v$mun_res == v$ent_res); n_mun <- uniqueN(v[, .(ent_res, mun_res)])
  if (pct_igual > 10 || n_mun < 1500)
    stop(sprintf("%d: MUNRESIDENCIA sospechosa (%.1f%% mun==ent, %d municipios distintos)", anio, pct_igual, n_mun))
  message(sprintf("%d: %s filas (descartadas %s) | fecha NA %.2f%% | ent_res fuera 1-32 %.2f%% | mun_res 998/999/NA %.2f%% | fecha fuera del año %.2f%% | mun==ent %.2f%% | municipios %d",
                  anio, format(n0, big.mark = ","), format(descartadas, big.mark = ","),
                  100 * mean(is.na(res$fecha)),
                  100 * mean(!res$ent_res %in% 1:32),
                  100 * mean(is.na(res$mun_res)),
                  100 * mean(year(res$fecha) != anio, na.rm = TRUE), pct_igual, n_mun))
  res
}

u <- rbindlist(lapply(archivos, leer_anio))
write_parquet(u, salida)
message("total: ", format(nrow(u), big.mark = ","), " filas -> ", salida)
