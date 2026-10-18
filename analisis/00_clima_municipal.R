#!/usr/bin/env Rscript
# Promedio diario municipal de una variable Daymet (un archivo NetCDF = una variable × un año).
# Mismo criterio que los .rds originales (raster::extract, media de celdas cuyo centro cae en el
# polígono); validado contra ellos: cor = 1, dif. máx. 0.02 °C (2022, 10 días).
# Uso: Rscript 00_clima_municipal.R <archivo.nc> <dir_salida>
# Salida: <dir_salida>/<nombre>.rds con columnas municipio, state, month, day, <var>_avg, year
# Requiere (R sin activar el env): GDAL_DRIVER_PATH=<env>/lib/gdalplugins PROJ_DATA=<env>/share/proj

suppressMessages({library(terra); library(data.table)})
terraOptions(progress = 0)

args   <- commandArgs(trailingOnly = TRUE)
nc     <- args[1]
salida <- file.path(args[2], sub("\\.nc$", ".rds", basename(nc)))
shp    <- "/STORAGE/genut/dalvarez/TEMP_URGENCIAS_MEXICO/Datos/municipios/mex_admbnda_adm2_govmex_20210618.shp"

partes <- strsplit(sub("\\.nc$", "", basename(nc)), "_")[[1]]   # daymet v4 daily na <var> <año>
var    <- partes[5]
anio   <- as.integer(partes[6])

r <- rast(nc, subds = var)
crs(r) <- "+proj=lcc +lat_0=42.5 +lon_0=-100 +lat_1=25 +lat_2=60 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
m <- project(vect(shp), crs(r))
n <- nlyr(r)
stopifnot(n == 365)   # Daymet: 365 días siempre (omite el 31-dic en bisiestos)

# fechas: Daymet omite el 31 de diciembre en años bisiestos
fechas <- seq(as.IDate(sprintf("%d-01-01", anio)), by = 1, length.out = 366)
if (n == 365 && (anio %% 4 == 0)) fechas <- fechas[fechas != as.IDate(sprintf("%d-12-31", anio))]
fechas <- fechas[seq_len(n)]

bloques <- split(seq_len(n), ceiling(seq_len(n) / 31))
res <- rbindlist(lapply(bloques, function(ix) {
  rb <- crop(r[[ix]], m)
  e  <- extract(rb, m, fun = mean, na.rm = TRUE, ID = FALSE)
  d  <- data.table(municipio = m$ADM2_ES, state = m$ADM1_ES, as.matrix(e))
  setnames(d, c("municipio", "state", as.character(ix)))
  melt(d, id.vars = c("municipio", "state"), variable.name = "k", value.name = "valor",
       variable.factor = FALSE)
}))
res[, k := as.integer(k)]
res[, `:=`(month = month(fechas[k]), day = mday(fechas[k]), year = as.character(anio))]
res <- res[, .(municipio, state, month, day, valor, year)]
setnames(res, "valor", paste0(var, "_avg"))

n_na <- sum(is.na(res[[paste0(var, "_avg")]]))
stopifnot(nrow(res) == length(m) * n, n_na == 0)
dir.create(dirname(salida), recursive = TRUE, showWarnings = FALSE)
saveRDS(res, salida)
message(sprintf("%s: %d municipios × %d días -> %s", basename(nc), length(m), n, salida))
