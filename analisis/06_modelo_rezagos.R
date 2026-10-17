#!/usr/bin/env Rscript
# Poisson con efectos fijos, todos los capítulos, rezagos 0-14 en ventanas
# (especificación: ESPECIFICACION_capitulos_rezagos.md).
# Uso: Rscript 06_modelo_rezagos.R <periodo> [capítulo ...]   (sin capítulos: los 16)
# Salida por capítulo: resultados/tablas/rezagos/<periodo>_<cap>.csv (+ _resumen.csv)
# Al final (si se corrieron todos): resultados/tablas/rezagos_<periodo>.csv y _resumen.csv

suppressMessages({library(data.table); library(arrow); library(fixest)})
nh <- as.integer(Sys.getenv("NHILOS", "8")); setDTthreads(nh); setFixest_nthreads(nh)

args    <- commandArgs(trailingOnly = TRUE)
periodo <- args[1]; stopifnot(!is.na(periodo))
cortes  <- c(-Inf, seq(12, 36, by = 3), Inf)
niveles <- levels(cut(0, cortes, right = FALSE))
ref_id  <- match("[24,27)", niveles)
ventanas <- c(v0 = 1, v1_3 = 3, v4_7 = 4, v8_14 = 7)   # días por ventana
dir_out <- "resultados/tablas/rezagos"
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

clima   <- as.data.table(read_parquet(sprintf("datos/derivados/clima_ventanas_%s.parquet", periodo)))
conteos <- as.data.table(read_parquet(sprintf("datos/derivados/conteos_capitulos_%s.parquet", periodo)))
clima[, `:=`(ent = cve %/% 1000L, anio = year(fecha), mes = month(fecha), dow = wday(fecha))]
caps <- if (length(args) > 1) args[-1] else c(sort(setdiff(unique(conteos$cap), "total")), "total")

regs <- as.vector(outer(names(ventanas), setdiff(seq_along(niveles), ref_id),
                        function(w, b) sprintf("n_%s_b%d", w, b)))
fml  <- as.formula(paste("casos ~", paste(regs, collapse = " + "),
                         "+ i(bp, ref = 1) | cve^anio^mes + ent^dow"))

for (cp in caps) {
  t0 <- Sys.time()
  d <- copy(clima)
  d[conteos[cap == cp], casos := i.casos, on = .(cve, fecha)]
  d[is.na(casos), casos := 0L]
  f <- fepois(fml, data = d, cluster = ~cve)
  b <- coef(f); V <- vcov(f)
  stopifnot(all(regs %in% names(b)))

  res <- rbindlist(lapply(setdiff(seq_along(niveles), ref_id), function(k) {
    nm <- sprintf("n_%s_b%d", names(ventanas), k)
    # perfil: efecto por día de rezago dentro de cada ventana
    perfil <- data.table(cap = cp, cantidad = names(ventanas), bin = niveles[k],
                         coef = b[nm], se = sqrt(diag(V[nm, nm])))
    # acumulado 0-14: suma de coeficientes por día de rezago
    w <- setNames(as.numeric(ventanas), nm)
    acum <- data.table(cap = cp, cantidad = "acumulado_0_14", bin = niveles[k],
                       coef = sum(w * b[nm]), se = sqrt(drop(t(w) %*% V[nm, nm] %*% w)))
    rbind(perfil, acum)
  }))
  res <- rbind(res, unique(res[, .(cap, cantidad)])[, .(cap, cantidad, bin = niveles[ref_id],
                                                       coef = 0, se = 0)])
  res[, `:=`(irr = exp(coef), irr_lo = exp(coef - 1.96 * se), irr_hi = exp(coef + 1.96 * se))]
  if (anyNA(res)) stop("NA en coeficientes de ", cp)
  fwrite(res, sprintf("%s/%s_%s.csv", dir_out, periodo, cp))
  fwrite(data.table(cap = cp, n_obs = nobs(f), n_mun = uniqueN(d[obs(f), cve]),
                    casos = sum(d[obs(f), casos]), obs_eliminadas = nrow(d) - nobs(f),
                    segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")))),
         sprintf("%s/%s_%s_resumen.csv", dir_out, periodo, cp))
  a <- res[cantidad == "acumulado_0_14" & bin == "[36, Inf)"]
  message(sprintf("%s: n=%d, >=36 acumulado 0-14 = %.3f [%.3f, %.3f] (%.0f s)", cp, nobs(f),
                  a$irr, a$irr_lo, a$irr_hi, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  rm(d, f); gc()
}

# junta todo si ya están los 16
todos <- c(sort(setdiff(unique(conteos$cap), "total")), "total")
arch  <- sprintf("%s/%s_%s.csv", dir_out, periodo, todos)
if (all(file.exists(arch))) {
  r <- rbindlist(lapply(arch, fread))
  r[, bin := factor(bin, levels = niveles)]
  setorder(r, cap, cantidad, bin)
  fwrite(r, sprintf("resultados/tablas/rezagos_%s.csv", periodo))
  fwrite(rbindlist(lapply(sub("\\.csv$", "_resumen.csv", arch), fread)),
         sprintf("resultados/tablas/rezagos_%s_resumen.csv", periodo))
  writeLines(capture.output(sessionInfo()), sprintf("resultados/tablas/rezagos_%s_sessionInfo.txt", periodo))
  message("-> resultados/tablas/rezagos_", periodo, ".csv")
}
