#!/usr/bin/env Rscript
# Prueba piloto: Poisson con efectos fijos, Tmax en bins de 3 °C.
# Especificación comprometida antes de ver resultados (records/REGISTRO.md, 2026-10-16):
#   casos ~ i(bin_tmax, ref = [24,27)) + i(bin_prcp) | cve^anio^mes + ent^dow
#   errores agrupados por municipio; secundario: rezagos 0-3 (suma de coeficientes).
# Uso: Rscript 03_modelo_piloto.R <periodo>   (p. ej. 2012_2025)
# Entrada: datos/derivados/panel_<periodo>.parquet
# Salida:  resultados/tablas/piloto_{coeficientes,resumen,sessionInfo}_<periodo>.*

suppressMessages({library(data.table); library(arrow); library(fixest)})
nh <- as.integer(Sys.getenv("NHILOS", "8")); setDTthreads(nh); setFixest_nthreads(nh)
periodo <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(!is.na(periodo))
dir.create("resultados/tablas", recursive = TRUE, showWarnings = FALSE)

cortes   <- c(-Inf, seq(12, 36, by = 3), Inf)
ref_bin  <- "[24,27)"
niveles  <- levels(cut(0, cortes, right = FALSE))
ref_id   <- match(ref_bin, niveles)
# código entero del bin: fixest nombra mal los términos si ref es "[24,27)"
bin_t    <- function(x) as.integer(cut(x, cortes, right = FALSE))
bin_p    <- function(x) cut(x, c(-Inf, 0.1, 5, 20, Inf), right = FALSE,
                            labels = c("0", "0.1-5", "5-20", ">20"))

panel <- as.data.table(read_parquet(sprintf("datos/derivados/panel_%s.parquet", periodo)))
panel[, `:=`(b0 = bin_t(tmax), b1 = bin_t(tmax_l1), b2 = bin_t(tmax_l2),
             b3 = bin_t(tmax_l3), bp = bin_p(prcp))]

coefs <- list(); resumen <- list()
for (cp in sort(unique(panel$cap))) {
  d <- panel[cap == cp]

  # principal: mismo día
  f0 <- fepois(casos ~ i(b0, ref = ref_id) + i(bp, ref = "0") | cve^anio^mes + ent^dow,
               data = d, cluster = ~cve)
  ct <- as.data.table(coeftable(f0), keep.rownames = "term")[grepl("^b0::", term)]
  coefs[[length(coefs) + 1]] <- ct[, .(cap = cp, modelo = "dia_0",
                                       bin = niveles[as.integer(sub("^b0::", "", term))],
                                       coef = Estimate, se = `Std. Error`)]

  # secundario: rezagos 0-3, efecto acumulado = suma de coeficientes por bin
  d3 <- d[!is.na(b1) & !is.na(b2) & !is.na(b3)]
  f3 <- fepois(casos ~ i(b0, ref = ref_id) + i(b1, ref = ref_id) + i(b2, ref = ref_id) +
                 i(b3, ref = ref_id) + i(bp, ref = "0") | cve^anio^mes + ent^dow,
               data = d3, cluster = ~cve)
  V <- vcov(f3); b <- coef(f3)
  acum <- rbindlist(lapply(setdiff(seq_along(niveles), ref_id), function(k) {
    nm <- paste0("b", 0:3, "::", k)
    stopifnot(all(nm %in% names(b)))   # los cuatro rezagos deben estar
    w  <- setNames(rep(1, length(nm)), nm)
    data.table(cap = cp, modelo = "acumulado_0_3", bin = niveles[k],
               coef = sum(b[nm]), se = sqrt(drop(t(w) %*% V[nm, nm] %*% w)))
  }))
  coefs[[length(coefs) + 1]] <- acum

  resumen[[length(resumen) + 1]] <- data.table(
    cap = cp, n_obs_dia0 = nobs(f0), n_mun_dia0 = uniqueN(d[obs(f0), cve]),
    casos_dia0 = sum(d[obs(f0), casos]), n_obs_acum = nobs(f3),
    obs_eliminadas_dia0 = nrow(d) - nobs(f0))
  message(cp, ": n=", nobs(f0), " municipios=", resumen[[length(resumen)]]$n_mun_dia0)
}

coefs <- rbindlist(coefs)
coefs[, `:=`(irr = exp(coef), irr_lo = exp(coef - 1.96 * se), irr_hi = exp(coef + 1.96 * se))]
# añade la categoría de referencia explícita (IRR = 1) para que la figura no invente nada
ref <- unique(coefs[, .(cap, modelo)])[, .(cap, modelo, bin = ref_bin, coef = 0, se = 0,
                                           irr = 1, irr_lo = 1, irr_hi = 1)]
coefs <- rbind(coefs, ref)
coefs[, bin := factor(bin, levels = niveles)]
setorder(coefs, cap, modelo, bin)
if (anyNA(coefs)) {
  fwrite(coefs, sprintf("resultados/tablas/piloto_coeficientes_CON_NA_%s.csv", periodo))
  print(coefs[!complete.cases(coefs)])
  stop("NA en coeficientes; ver resultados/tablas/piloto_coeficientes_CON_NA.csv")
}

fwrite(coefs, sprintf("resultados/tablas/piloto_coeficientes_%s.csv", periodo))
fwrite(rbindlist(resumen), sprintf("resultados/tablas/piloto_resumen_%s.csv", periodo))
writeLines(capture.output(sessionInfo()), sprintf("resultados/tablas/piloto_sessionInfo_%s.txt", periodo))
message("-> resultados/tablas/piloto_*.csv")
