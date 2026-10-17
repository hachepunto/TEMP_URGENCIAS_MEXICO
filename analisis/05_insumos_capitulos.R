#!/usr/bin/env Rscript
# Insumos para el modelo de todos los capítulos con rezagos 0-14
# (especificación: ESPECIFICACION_capitulos_rezagos.md).
# Entrada: datos/derivados/urgencias_2012_2025.parquet (01_leer_urgencias.R) y .rds de clima
# Salida:  datos/derivados/conteos_capitulos_2012_2025.parquet  (cve, fecha, cap, casos; sin ceros)
#          datos/derivados/clima_ventanas_2012_2025.parquet     (cve, fecha, bins y conteos por ventana)

suppressMessages({library(data.table); library(arrow)})
setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))

anios   <- 2012:2025
dbf     <- "../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf"
dir_temp <- function(a) sprintf("/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL/%s",
                                ifelse(a <= 2022, "day_results", "day_results_v4r1"))
cortes  <- c(-Inf, seq(12, 36, by = 3), Inf)
ventanas <- list(v0 = 0L, v1_3 = 1:3, v4_7 = 4:7, v8_14 = 8:14)

# --- capítulos CIE-10 por rango de código de 3 caracteres ------------------------
capitulos <- data.table(
  cap = c("infecciosas", "sangre", "endocrinas", "mentales", "nervioso", "ojo", "oido",
          "circulatorio", "respiratorio", "digestivo", "piel", "osteomuscular",
          "genitourinario", "sintomas", "traumatismos"),
  desde = c("A00", "D50", "E00", "F00", "G00", "H00", "H60", "I00", "J00", "K00", "L00",
            "M00", "N00", "R00", "S00"),
  hasta = c("B99", "D89", "E90", "F99", "G99", "H59", "H95", "I99", "J99", "K93", "L99",
            "M99", "N99", "R99", "T98"))

# --- municipios -------------------------------------------------------------------
m <- as.data.table(foreign::read.dbf(dbf, as.is = TRUE))
m <- m[, .(municipio = ADM2_ES, state = ADM1_ES, cve = as.integer(sub("^MX", "", ADM2_PCODE)))]
stopifnot(!anyDuplicated(m[, .(municipio, state)]), !anyDuplicated(m$cve))

# --- conteos por capítulo ---------------------------------------------------------
u <- as.data.table(read_parquet("datos/derivados/urgencias_2012_2025.parquet",
                                col_select = c("fecha", "ent_res", "mun_res", "cie3")))
u <- u[ent_res %in% 1:32 & !is.na(mun_res) & mun_res < 999 &
         fecha >= as.IDate(sprintf("%d-01-01", min(anios))) &
         fecha <= as.IDate(sprintf("%d-12-31", max(anios)))]
u[, cve := ent_res * 1000L + mun_res]
u <- u[cve %in% m$cve]
# asignación por rango con llave numérica (letra*100 + número); cada código cae a lo más en uno
llave <- function(x) match(substr(x, 1, 1), LETTERS) * 100L +
  suppressWarnings(as.integer(substr(x, 2, 3)))
cods <- data.table(cie3 = unique(u$cie3))[, k := llave(cie3)]
capitulos[, `:=`(k1 = llave(desde), k2 = llave(hasta))]
cods[capitulos, cap := i.cap, on = .(k >= k1, k <= k2)]
stopifnot(cods[!is.na(cap), !anyDuplicated(cie3)])
message("códigos sin llave numérica (3er carácter no dígito): ", cods[is.na(k), .N])
u[cods, cap := i.cap, on = "cie3"]
message("atenciones con residencia válida: ", format(nrow(u), big.mark = ","),
        "; en los 15 capítulos: ", format(u[!is.na(cap), .N], big.mark = ","))
print(u[!is.na(cap), .N, by = cap][order(-N)])
conteos <- u[!is.na(cap), .(casos = .N), by = .(cve, fecha, cap)]
conteos <- rbind(conteos, conteos[, .(cap = "total", casos = sum(casos)), by = .(cve, fecha)],
                 use.names = TRUE)
write_parquet(conteos, sprintf("datos/derivados/conteos_capitulos_%d_%d.parquet", min(anios), max(anios)))
rm(u); gc()

# --- clima diario, con el 31-dic de años bisiestos imputado ---------------------
leer_var <- function(var) {
  rbindlist(lapply(c(min(anios) - 1, anios), function(a) {
    x <- as.data.table(readRDS(sprintf("%s/daymet_v4_daily_na_%s_%d.rds", dir_temp(a), var, a)))
    x[, fecha := as.IDate(sprintf("%s-%02d-%02d", year, month, day))]
    x[, .(municipio, state, fecha, valor = get(paste0(var, "_avg")))]
  }))
}
clima <- merge(leer_var("tmax")[, .(municipio, state, fecha, tmax = valor)],
               leer_var("prcp")[, .(municipio, state, fecha, prcp = valor)],
               by = c("municipio", "state", "fecha"))
clima <- merge(clima, m, by = c("municipio", "state"))[, .(cve, fecha, tmax, prcp)]
bisiestos <- c(min(anios) - 1, anios)[c(min(anios) - 1, anios) %% 4 == 0]
dic31 <- clima[fecha %in% as.IDate(sprintf("%d-12-30", bisiestos))][, fecha := fecha + 1L]
stopifnot(!nrow(clima[dic31, on = .(cve, fecha), nomatch = 0]))   # no existían
clima <- rbind(clima, dic31)
setkey(clima, cve, fecha)
dias_esperados <- as.integer(as.IDate(sprintf("%d-12-31", max(anios))) -
                               as.IDate(sprintf("%d-01-01", min(anios) - 1))) + 1L
stopifnot(!anyNA(clima), clima[, .N, by = cve][, all(N == dias_esperados)])
message("clima: ", uniqueN(clima$cve), " municipios × ", dias_esperados, " días (", length(bisiestos),
        " 31-dic imputados con el 30-dic)")

# --- bins y conteos por ventana de rezago (unión por llave cve+fecha) ---------------
clima[, bin := as.integer(cut(tmax, cortes, right = FALSE))]
clima[, bp := as.integer(cut(prcp, c(-Inf, 0.1, 5, 20, Inf), right = FALSE))]
for (k in 1:14) {
  lk <- clima[, .(cve, fecha = fecha + k, b = bin)]
  clima[lk, (paste0("bin_l", k)) := i.b, on = .(cve, fecha)]
}
clima[, bin_l0 := bin]
clima <- clima[fecha >= as.IDate(sprintf("%d-01-01", min(anios)))]
stopifnot(!anyNA(clima[, paste0("bin_l", 0:14), with = FALSE]))
nb <- length(cortes) - 1L
for (w in names(ventanas)) for (b in seq_len(nb)) {
  cols <- paste0("bin_l", ventanas[[w]])
  clima[, (sprintf("n_%s_b%d", w, b)) := Reduce(`+`, lapply(.SD, function(z) as.integer(z == b))),
        .SDcols = cols]
}
clima[, paste0("bin_l", 0:14) := NULL]
# chequeo: en cada ventana los conteos suman su número de días
for (w in names(ventanas)) {
  s <- rowSums(clima[, sprintf("n_%s_b%d", w, seq_len(nb)), with = FALSE])
  stopifnot(all(s == length(ventanas[[w]])))
}
write_parquet(clima, sprintf("datos/derivados/clima_ventanas_%d_%d.parquet", min(anios), max(anios)))
message("clima_ventanas: ", format(nrow(clima), big.mark = ","), " filas, ", ncol(clima), " columnas")
