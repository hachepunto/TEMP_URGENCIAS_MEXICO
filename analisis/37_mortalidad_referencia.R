#!/usr/bin/env Rscript
# Especificación L-a3 (ESPECIFICACION_referencia_L-a3.md): ¿el gradiente inverso de mortalidad por calor es un
# artefacto de la referencia 24-27 °C? Contrastes entre bins con la covarianza guardada por 06; sin modelos nuevos.
# Entrada: resultados/tablas/rezagos_defunciones[_edad]_marg<k>_expo-fino/2012_2025_<cap>{.csv,_vcov.rds} (06, EXPO=fino; L-a2)
#          resultados/tablas/rezagos_defunciones[_edad]_marg<k>/2012_2025_<cap>{.csv,_vcov.rds} (06, EXPO=tmax; G)
# Salida:  resultados/tablas/mortalidad_referencia_2012_2025.csv (contrastes M3/M1 y criterio),
#          mortalidad_referencia_forma_2012_2025.csv (secundario 2: M3/M1 de 27-36 °C frente a 24-27)
suppressMessages(library(data.table))
T <- "resultados/tablas"; r0 <- 0.921; per <- "2012_2025"
pesos <- c(v0 = 1, v1_3 = 3, v4_7 = 4, v8_14 = 7)   # días por ventana: acumulado 0-14 = suma ponderada
niv_fino <- levels(cut(0, c(-Inf, seq(12, 36, by = 3), 38, 40, Inf), right = FALSE))
niv_tmax <- levels(cut(0, c(-Inf, seq(12, 36, by = 3), Inf), right = FALSE))
ref <- "[24,27)"; caps <- c("todas", "circulatorio", "todas_65mas")
dir_m <- function(cp, k, expo) sprintf("%s/rezagos_defunciones%s_marg%d%s", T, if (cp == "todas_65mas") "_edad" else "", k, if (expo == "fino") "_expo-fino" else "")

# log-IRR acumulado de bin a frente a bin b (cualquiera puede ser la referencia, con coeficiente 0)
contraste <- function(cp, k, expo, a, b) {
  niv <- if (expo == "fino") niv_fino else niv_tmax
  V <- readRDS(file.path(dir_m(cp, k, expo), sprintf("%s_%s_vcov.rds", per, cp))); cf <- attr(V, "coef")
  w <- setNames(numeric(length(cf)), names(cf))
  for (bb in c(a, b)) if (bb != ref) {
    nm <- sprintf("n_%s_b%d", names(pesos), match(bb, niv)); stopifnot(all(nm %in% names(cf)))
    w[nm] <- w[nm] + pesos * if (bb == a) 1 else -1
  }
  # comprobación contra el acumulado que escribió 06
  acu <- fread(file.path(dir_m(cp, k, expo), sprintf("%s_%s.csv", per, cp)))[cantidad == "acumulado_0_14"]
  stopifnot(abs(sum(w * cf) - (acu[bin == a, coef] - acu[bin == b, coef])) < 1e-8)
  data.table(cap = cp, marg = k, expo, bin = a, frente_a = b, coef = sum(w * cf), se = sqrt(drop(t(w) %*% V %*% w)))
}
cociente <- function(x) {
  w <- dcast(x, cap + expo + bin + frente_a ~ marg, value.var = c("coef", "se"))
  w[, `:=`(T1 = exp(coef_1), T2 = exp(coef_2), T3 = exp(coef_3), ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
  w[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)), ancho_log = 2 * 1.96 * se_r)][]
}
todos <- function(expo, a, b) rbindlist(lapply(caps, function(cp) rbindlist(lapply(1:3, function(k) contraste(cp, k, expo, a, b)))))

# --- principal y secundario 1 -------------------------------------------------------
pri <- cociente(todos("fino", "[36,38)", "[33,36)"))[, `:=`(parte = "L-a3 principal", q = p.adjust(p, "BH"))]
s1  <- rbind(cociente(todos("fino", "[38,40)", "[33,36)")), cociente(todos("fino", "[40, Inf)", "[33,36)")),
             cociente(todos("tmax", "[36, Inf)", "[33,36)")))[, parte := "L-a3 sec. 1: desde 33-36"]
# --- secundario 3: TMM por tercil (bin con menor acumulado entre 24-27 y 33-36, modelo L-a2) ----
cand <- c("[24,27)", "[27,30)", "[30,33)", "[33,36)")
tmm <- rbindlist(lapply(caps, function(cp) rbindlist(lapply(1:3, function(k) {
  acu <- fread(file.path(dir_m(cp, k, "fino"), sprintf("%s_%s.csv", per, cp)))[cantidad == "acumulado_0_14" & bin %in% cand]
  data.table(cap = cp, marg = k, tmm = acu[which.min(coef), bin])
}))))
cat("TMM por tercil (bin de menor IRR acumulado, 24-36 °C):\n"); print(dcast(tmm, cap ~ marg, value.var = "tmm"))
s3 <- rbindlist(lapply(seq_len(nrow(tmm)), function(i) contraste(tmm$cap[i], tmm$marg[i], "fino", "[36,38)", tmm$tmm[i])))
s3 <- merge(s3, tmm, by = c("cap", "marg"))
s3w <- dcast(s3, cap + expo + bin ~ marg, value.var = c("coef", "se", "tmm"))
s3w[, `:=`(frente_a = paste0("TMM ", tmm_1, " / ", tmm_3), T1 = exp(coef_1), T2 = exp(coef_2), T3 = exp(coef_3), ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
s3w[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)), ancho_log = 2 * 1.96 * se_r, parte = "L-a3 sec. 3: desde TMM")]

cols <- c("parte", "cap", "expo", "bin", "frente_a", "T1", "T2", "T3", "ratio", "lo", "hi", "p", "q", "ancho_log")
out <- rbind(pri, s1, s3w, fill = TRUE)[, ..cols]
fwrite(out, file.path(T, "mortalidad_referencia_2012_2025.csv"))
cat("\nCocientes M3/M1 de razones de tasas acumuladas 0-14 entre bins:\n")
print(out[, lapply(.SD, function(v) if (is.numeric(v)) signif(v, 3) else v)], nrows = 50)

# --- secundario 2: dónde se forma el gradiente (G, EXPO=tmax, frente a 24-27) -----------
forma <- rbindlist(lapply(c("[27,30)", "[30,33)", "[33,36)", "[36, Inf)"), function(b) cociente(todos("tmax", b, ref))))
forma <- forma[, .(cap, bin, T1, T2, T3, ratio, lo, hi, p, ancho_log)]
fwrite(forma, file.path(T, "mortalidad_referencia_forma_2012_2025.csv"))
cat("\nSecundario 2, M3/M1 frente a 24-27 °C (G):\n"); print(forma[, lapply(.SD, function(v) if (is.numeric(v)) signif(v, 3) else v)])

x <- out[parte == "L-a3 principal" & cap == "todas"]
stopifnot(nrow(x) == 1)
v <- if (x$lo <= 1 && x$hi >= 1 && abs(log(x$ratio)) < abs(log(r0))) "REFERENCIA (el gradiente es un artefacto de medir desde 24-27 °C)" else
     if (x$hi < 1 && x$ancho_log < 0.4) "NO es la referencia" else
     if (x$lo > 1) "INVERSIÓN (desde un día cálido, M3 sufre más)" else "INDETERMINADO"
cat(sprintf("\nL-a3: todas 36-38 frente a 33-36, M3/M1 %.3f [%.3f, %.3f] (ancho log %.2f; referencia %.3f) -> %s\n", x$ratio, x$lo, x$hi, x$ancho_log, r0, v))
