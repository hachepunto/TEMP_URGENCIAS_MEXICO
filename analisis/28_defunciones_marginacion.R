#!/usr/bin/env Rscript
# Especificación G, contrastes (ii) y (iii): gradiente por marginación en mortalidad.
# (ii) cociente M3/M1 del acumulado 0-14 a >= 36 °C por desenlace (terciles CONAPO 2020), con urgencias
#      en los mismos terciles al lado;
# (iii) lo mismo dentro de cada estrato de clima de base (todas y circulatorio), con la regla de celda de
#      la especificación E (>= 2,000 municipio-días y >= 50 municipios en >= 36; si no, [33,36)).
# EE del log-cociente por suma de varianzas (estratos independientes); BH dentro de cada contraste.
# Entrada: resultados/tablas/rezagos_defunciones_marg<k>_2012_2025.csv, rezagos_marg<k>_2012_2025.csv,
#          rezagos_defunciones_clima<j>_marg<k>/ (06), celdas_clima_marg.csv (13)
# Salida:  resultados/tablas/defunciones_marginacion_2012_2025.csv, defunciones_clima_marg_2012_2025.csv
suppressMessages(library(data.table))
T <- "resultados/tablas"
cociente <- function(w) {
  w[, `:=`(ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
  w[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)))]
  w[, q := p.adjust(p, "BH")][]
}

# --- (ii) ---
leer_marg <- function(patron) rbindlist(lapply(1:3, function(k)
  fread(sprintf(patron, k))[cantidad == "acumulado_0_14" & bin == "[36, Inf)", .(cap, coef, se, marg = k)]))
d <- dcast(leer_marg(file.path(T, "rezagos_defunciones_marg%d_2012_2025.csv")), cap ~ marg, value.var = c("coef", "se"))
d <- cociente(d)
u <- dcast(leer_marg(file.path(T, "rezagos_marg%d_2012_2025.csv")), cap ~ marg, value.var = c("coef", "se"))
u <- cociente(u)
ii <- rbind(d[, .(fuente = "defunciones", cap, M1 = exp(coef_1), M2 = exp(coef_2), M3 = exp(coef_3), ratio, lo, hi, q)],
            u[, .(fuente = "urgencias", cap, M1 = exp(coef_1), M2 = exp(coef_2), M3 = exp(coef_3), ratio, lo, hi, q)])
fwrite(ii, file.path(T, "defunciones_marginacion_2012_2025.csv"))
cat("(ii) acumulado 0-14 a >= 36 por tercil de marginación, M3/M1 (BH dentro de cada fuente):\n")
print(ii[, .(fuente, cap, M1 = round(M1, 3), M2 = round(M2, 3), M3 = round(M3, 3), ratio = round(ratio, 3), lo = round(lo, 3), hi = round(hi, 3), q = signif(q, 2))][order(fuente, ratio)], nrows = 40)

# --- (iii) ---
cel <- fread(file.path(T, "celdas_clima_marg.csv"))
r <- rbindlist(lapply(1:3, function(j) {
  b <- cel[clima == j & marg %in% c(1, 3), if (all(ge36_identificado)) "[36, Inf)" else "[33,36)"]
  rbindlist(lapply(c(1, 3), function(k) rbindlist(lapply(c("todas", "circulatorio"), function(cp) {
    f <- sprintf("%s/rezagos_defunciones_clima%d_marg%d/2012_2025_%s.csv", T, j, k, cp)
    if (!file.exists(f)) return(NULL)
    fread(f)[cantidad == "acumulado_0_14" & bin == b, .(cap, clima = j, marg = k, bin, coef, se)]
  }))))
}))
iii <- cociente(dcast(r, cap + clima + bin ~ marg, value.var = c("coef", "se")))
iii[, `:=`(M1 = exp(coef_1), M3 = exp(coef_3))]
fwrite(iii[, .(cap, clima, bin, M1, M3, ratio, lo, hi, q)], file.path(T, "defunciones_clima_marg_2012_2025.csv"))
cat("\n(iii) M3/M1 dentro de cada estrato de clima de base (todas, circulatorio):\n")
print(iii[, .(cap, clima, bin, M1 = round(M1, 3), M3 = round(M3, 3), ratio = round(ratio, 3), lo = round(lo, 3), hi = round(hi, 3), q = signif(q, 2))])
message("-> defunciones_marginacion_2012_2025.csv, defunciones_clima_marg_2012_2025.csv")
