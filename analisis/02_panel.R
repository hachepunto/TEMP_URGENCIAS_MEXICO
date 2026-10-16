#!/usr/bin/env Rscript
# Construye el panel municipio de residencia × día × capítulo, 2012-2022, con ceros
# explícitos, unido a Tmax y precipitación diarias del municipio (Daymet, promedio de polígono).
# Entrada: datos/derivados/urgencias_2012_2022.parquet (01_leer_urgencias.R)
# Salida:  datos/derivados/panel_2012_2022.parquet

suppressMessages({library(data.table); library(arrow)})
setDTthreads(16)

dir_temp <- "/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL/day_results"
dbf      <- "../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf"
salida   <- "datos/derivados/panel_2012_2022.parquet"
anios    <- 2012:2022

# capítulos de la prueba piloto (por letra del código CIE-10)
capitulos <- data.table(
  letra = c("I", "N", "S", "T"),
  cap   = c("circulatorio", "genitourinario", "traumatismos", "traumatismos")
)

# --- municipios: nombre (como en los .rds) -> clave INEGI -----------------------
m <- as.data.table(foreign::read.dbf(dbf, as.is = TRUE))
m <- m[, .(municipio = ADM2_ES, state = ADM1_ES,
           cve = as.integer(sub("^MX", "", ADM2_PCODE)))]
stopifnot(!anyDuplicated(m[, .(municipio, state)]), !anyDuplicated(m$cve))

# --- clima diario (incluye 2011 para rezagos) ------------------------------------
leer_var <- function(var) {
  rbindlist(lapply(c(min(anios) - 1, anios), function(a) {
    x <- as.data.table(readRDS(sprintf("%s/daymet_v4_daily_na_%s_%d.rds", dir_temp, var, a)))
    x[, fecha := as.IDate(sprintf("%s-%02d-%02d", year, month, day))]
    x[, .(municipio, state, fecha, valor = get(paste0(var, "_avg")))]
  }))
}
clima <- merge(leer_var("tmax")[, .(municipio, state, fecha, tmax = valor)],
               leer_var("prcp")[, .(municipio, state, fecha, prcp = valor)],
               by = c("municipio", "state", "fecha"))
clima <- merge(clima, m, by = c("municipio", "state"))[, .(cve, fecha, tmax, prcp)]
stopifnot(!anyNA(clima))
# Daymet usa calendario de 365 días: el 31-dic de años bisiestos no existe
setkey(clima, cve, fecha)
message("clima: ", uniqueN(clima$cve), " municipios, ", uniqueN(clima$fecha), " días")

# --- conteos de urgencias por residencia ----------------------------------------
u <- as.data.table(read_parquet(
  "datos/derivados/urgencias_2012_2022.parquet",
  col_select = c("fecha", "ent_res", "mun_res", "cie3")))
n_total <- nrow(u)
u <- u[ent_res %in% 1:32 & !is.na(mun_res) & mun_res < 999 &
         fecha >= as.IDate("2012-01-01") & fecha <= as.IDate("2022-12-31")]
u[, letra := substr(cie3, 1, 1)]
u <- merge(u, capitulos, by = "letra")
u[, cve := ent_res * 1000L + mun_res]
n_cap <- nrow(u)
sin_clima <- u[!cve %in% m$cve, .N]
conteos <- u[cve %in% m$cve, .(casos = .N), by = .(cve, fecha, cap)]
message(sprintf("atenciones: %s totales; %s en capítulos piloto con residencia válida; %.2f%% con clave municipal sin clima (descartadas)",
                format(n_total, big.mark = ","), format(n_cap, big.mark = ","), 100 * sin_clima / n_cap))
rm(u); gc()

# --- panel completo con ceros ---------------------------------------------------
dias  <- clima[fecha >= as.IDate("2012-01-01"), sort(unique(fecha))]
panel <- CJ(cve = m$cve, fecha = dias, cap = unique(capitulos$cap))
panel <- merge(panel, conteos, by = c("cve", "fecha", "cap"), all.x = TRUE)
fuera <- conteos[!panel, on = .(cve, fecha, cap), sum(casos)]   # 31-dic bisiestos
panel[is.na(casos), casos := 0L]
message(sprintf("panel: %s filas; %.1f%% ceros; casos fuera del calendario Daymet: %s",
                format(nrow(panel), big.mark = ","), 100 * mean(panel$casos == 0), fuera))

# rezagos de Tmax (días 1-3) desde la serie de clima, por clave y fecha (no por posición)
for (k in 1:3) {
  lag_k <- clima[, .(cve, fecha = fecha + k, tmax_l = tmax)]
  setnames(lag_k, "tmax_l", paste0("tmax_l", k))
  clima <- merge(clima, lag_k, by = c("cve", "fecha"), all.x = TRUE)
}
panel <- merge(panel, clima, by = c("cve", "fecha"))
panel[, `:=`(ent = cve %/% 1000L, anio = year(fecha), mes = month(fecha),
             dow = wday(fecha))]
stopifnot(!anyNA(panel[, .(casos, tmax, prcp)]))
message("rezagos NA (tras 29-feb/1-ene sin día previo en Daymet): ",
        panel[is.na(tmax_l1) | is.na(tmax_l2) | is.na(tmax_l3), .N])

write_parquet(panel, salida)
message("-> ", salida)
