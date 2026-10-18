#!/usr/bin/env Rscript
# Poisson con efectos fijos, todos los capítulos, rezagos 0-14 en ventanas
# (especificación: ESPECIFICACION_capitulos_rezagos.md).
# Uso: Rscript 06_modelo_rezagos.R <periodo> [capítulo ...]   (sin capítulos: todos los del archivo)
# Variables de entorno (ESPECIFICACION_sensibilidad_subgrupos.md):
#   FE_SPEC=base (cve^anio^mes + ent^dow) | anio_semana (cve^anio + ent^semana + ent^dow)
#   CONTEOS=capitulos (default) | subgrupos | hospital | defunciones | codigos -> datos/derivados/conteos_<CONTEOS>_<periodo>.parquet
#   (codigos: 164 códigos CIE-10 de 3 caracteres, ESPECIFICACION_codigos.md; se corre por lotes con la lista de códigos como argumentos)
#   (defunciones: 2012-2024; el clima 2025 queda con ceros y lo descarta fepois por celdas vacías; se recorta abajo)
#   MARG=1|2|3  restringe a un tercil de marginación CONAPO 2020 (datos/derivados/marginacion_terciles_2020.csv)
#   CLIMA=1|2|3 restringe a un tercil de clima de base (datos/derivados/clima_base_terciles.csv)
#   VENTANAS=30 usa clima_ventanas30 (ventanas 0,1-3,4-7,8-14,15-21,22-30; acumulado 0-30)
#   ANIO_MIN=2014 excluye años anteriores (sensibilidad sin 2012)
#   EXPO=tmax (default) | at (temperatura aparente) | hum (Tmax con bins >= 33 partidos seco/húmedo) -> clima_ventanas_<EXPO> (ESPECIFICACION_humedad.md)
# Salida por desenlace: resultados/tablas/rezagos<sufijo>/<periodo>_<cap>.csv (+ _resumen.csv)
# Al final (si están todos): resultados/tablas/rezagos<sufijo>_<periodo>.csv y _resumen.csv
# sufijo = "" para base/capitulos; "_fe-anio_semana", "_subgrupos", "_marg<k>" en los demás casos.

suppressMessages({library(data.table); library(arrow); library(fixest)})
nh <- as.integer(Sys.getenv("NHILOS", "8")); setDTthreads(nh); setFixest_nthreads(nh)

args    <- commandArgs(trailingOnly = TRUE)
periodo <- args[1]; stopifnot(!is.na(periodo))
cortes  <- c(-Inf, seq(12, 36, by = 3), Inf)
niveles <- levels(cut(0, cortes, right = FALSE))
expo    <- Sys.getenv("EXPO", "tmax"); stopifnot(expo %in% c("tmax", "at", "hum"))   # ESPECIFICACION_humedad.md
if (expo == "hum") niveles <- c(niveles[1:8], "[33,36) seco", "[33,36) humedo", "[36, Inf) seco", "[36, Inf) humedo")
ref_id  <- match("[24,27)", niveles)
v30 <- Sys.getenv("VENTANAS", "14") == "30"; anio_min <- as.integer(Sys.getenv("ANIO_MIN", "0"))
ventanas <- if (v30) c(v0 = 1, v1_3 = 3, v4_7 = 4, v8_14 = 7, v15_21 = 7, v22_30 = 9) else c(v0 = 1, v1_3 = 3, v4_7 = 4, v8_14 = 7)   # días por ventana
acum_lab <- if (v30) "acumulado_0_30" else "acumulado_0_14"
fe_spec <- Sys.getenv("FE_SPEC", "base"); conteos_tipo <- Sys.getenv("CONTEOS", "capitulos")
stopifnot(fe_spec %in% c("base", "anio_semana"), conteos_tipo %in% c("capitulos", "subgrupos", "hospital", "defunciones", "codigos"))
marg    <- Sys.getenv("MARG", ""); stopifnot(marg %in% c("", "1", "2", "3"))
clima_e <- Sys.getenv("CLIMA", ""); stopifnot(clima_e %in% c("", "1", "2", "3"))
sufijo  <- paste0(if (fe_spec != "base") paste0("_fe-", fe_spec), if (conteos_tipo != "capitulos") paste0("_", conteos_tipo),
                  if (clima_e != "") paste0("_clima", clima_e), if (marg != "") paste0("_marg", marg),
                  if (v30) "_v30", if (anio_min > 0) paste0("_desde", anio_min), if (expo != "tmax") paste0("_expo-", expo))
if (length(sufijo) == 0) sufijo <- ""   # paste0 de puros NULL devuelve character(0)
fe      <- switch(fe_spec, base = "cve^anio^mes + ent^dow", anio_semana = "cve^anio + ent^semana + ent^dow")
dir_out <- paste0("resultados/tablas/rezagos", sufijo)
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

stopifnot(!(v30 && expo != "tmax"))
clima   <- as.data.table(read_parquet(sprintf("datos/derivados/clima_ventanas%s_%s.parquet",
                                              if (v30) "30" else if (expo != "tmax") paste0("_", expo) else "", periodo)))
if (anio_min > 0) clima <- clima[year(fecha) >= anio_min]
if (conteos_tipo == "defunciones") clima <- clima[fecha <= as.IDate("2024-12-31")]
conteos <- as.data.table(read_parquet(sprintf("datos/derivados/conteos_%s_%s.parquet", conteos_tipo, periodo)))
if (clima_e != "") {
  cb <- fread("datos/derivados/clima_base_terciles.csv")
  clima <- clima[cve %in% cb[clima == as.integer(clima_e), cve]]
  message("tercil de clima de base ", clima_e, ": ", uniqueN(clima$cve), " municipios")
}
if (marg != "") {
  terc <- fread("datos/derivados/marginacion_terciles_2020.csv")
  clima <- clima[cve %in% terc[tercil == as.integer(marg), cve]]
  message("tercil de marginación ", marg, ": ", uniqueN(clima$cve), " municipios")
}
clima[, `:=`(ent = cve %/% 1000L, anio = year(fecha), mes = month(fecha), dow = wday(fecha),
             semana = pmin((yday(fecha) - 1L) %/% 7L + 1L, 52L))]   # semana del año (no ISO: 29-31 dic quedan en el año)
todos <- if (conteos_tipo %in% c("capitulos", "hospital")) c(sort(setdiff(unique(conteos$cap), "total")), "total") else sort(unique(conteos$cap))
caps  <- if (length(args) > 1) args[-1] else todos

regs <- as.vector(outer(names(ventanas), setdiff(seq_along(niveles), ref_id),
                        function(w, b) sprintf("n_%s_b%d", w, b)))
fml  <- as.formula(paste("casos ~", paste(regs, collapse = " + "),
                         "+ i(bp, ref = 1) |", fe))
message("FE: ", fe, " | conteos: ", conteos_tipo)

for (cp in caps) {
  t0 <- Sys.time()
  d <- copy(clima)
  d[conteos[cap == cp], casos := i.casos, on = .(cve, fecha)]
  d[is.na(casos), casos := 0L]
  f <- fepois(fml, data = d, cluster = ~cve)
  b <- coef(f); V <- vcov(f)
  V2 <- vcov(f, vcov = ~cve + fecha)   # sensibilidad de inferencia: agrupamiento bidireccional municipio + fecha
  stopifnot(all(regs %in% names(b)))

  res <- rbindlist(lapply(setdiff(seq_along(niveles), ref_id), function(k) {
    nm <- sprintf("n_%s_b%d", names(ventanas), k)
    # perfil: efecto por día de rezago dentro de cada ventana
    perfil <- data.table(cap = cp, cantidad = names(ventanas), bin = niveles[k],
                         coef = b[nm], se = sqrt(diag(V[nm, nm])), se_2way = sqrt(diag(V2[nm, nm])))
    # acumulado 0-14: suma de coeficientes por día de rezago
    w <- setNames(as.numeric(ventanas), nm)
    acum <- data.table(cap = cp, cantidad = acum_lab, bin = niveles[k],
                       coef = sum(w * b[nm]), se = sqrt(drop(t(w) %*% V[nm, nm] %*% w)),
                       se_2way = sqrt(drop(t(w) %*% V2[nm, nm] %*% w)))
    rbind(perfil, acum)
  }))
  res <- rbind(res, unique(res[, .(cap, cantidad)])[, .(cap, cantidad, bin = niveles[ref_id],
                                                       coef = 0, se = 0, se_2way = 0)])
  res[, `:=`(irr = exp(coef), irr_lo = exp(coef - 1.96 * se), irr_hi = exp(coef + 1.96 * se),
             irr_lo_2way = exp(coef - 1.96 * se_2way), irr_hi_2way = exp(coef + 1.96 * se_2way))]
  if (anyNA(res)) stop("NA en coeficientes de ", cp)
  fwrite(res, sprintf("%s/%s_%s.csv", dir_out, periodo, cp))
  fwrite(data.table(cap = cp, fe = fe_spec, n_obs = nobs(f), n_mun = uniqueN(d[obs(f), cve]),
                    casos = sum(d[obs(f), casos]), obs_eliminadas = nrow(d) - nobs(f), bic = BIC(f), expo = expo,
                    segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")))),
         sprintf("%s/%s_%s_resumen.csv", dir_out, periodo, cp))
  a <- res[cantidad == acum_lab & bin == niveles[length(niveles)]]   # bin superior (en EXPO=hum, "[36, Inf) humedo")
  message(sprintf("%s: n=%d, %s %s = %.3f [%.3f, %.3f] (%.0f s)", cp, nobs(f), niveles[length(niveles)], acum_lab,
                  a$irr, a$irr_lo, a$irr_hi, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(d, f); gc()
}

# junta todo si ya están los 16
arch  <- sprintf("%s/%s_%s.csv", dir_out, periodo, todos)
if (all(file.exists(arch))) {
  r <- rbindlist(lapply(arch, fread))
  r[, bin := factor(bin, levels = niveles)]
  setorder(r, cap, cantidad, bin)
  fwrite(r, sprintf("resultados/tablas/rezagos%s_%s.csv", sufijo, periodo))
  fwrite(rbindlist(lapply(sub("\\.csv$", "_resumen.csv", arch), fread)),
         sprintf("resultados/tablas/rezagos%s_%s_resumen.csv", sufijo, periodo))
  writeLines(capture.output(sessionInfo()), sprintf("resultados/tablas/rezagos%s_%s_sessionInfo.txt", sufijo, periodo))
  message("-> resultados/tablas/rezagos", sufijo, "_", periodo, ".csv")
}
