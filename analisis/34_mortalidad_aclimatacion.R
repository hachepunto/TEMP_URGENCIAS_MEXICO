#!/usr/bin/env Rscript
# Especificación L-a (ESPECIFICACION_aclimatacion_L.md): con Tmax en percentiles locales, ¿el exceso de
# mortalidad sigue siendo menor en el tercil más marginado? Aplica el criterio comprometido en código.
# Entrada: datos/derivados/tmax_percentiles_municipio.csv (33), marginacion_terciles_2020.csv (11);
#          resultados/tablas/rezagos_defunciones[_edad][_marg<k>]_expo-rel/2012_2025_<cap>.csv (06, EXPO=rel)
# Salida:  resultados/tablas/mortalidad_aclimatacion_2012_2025.csv (cocientes M3/M1 y criterio) y
#          mortalidad_aclimatacion_curvas_2012_2025.csv (IRR acumulado 0-14 por percentil, nacional y por tercil),
#          mortalidad_aclimatacion_descriptivos_2012_2025.csv (percentiles y días >= 36 °C por tercil)
suppressMessages(library(data.table))
T <- "resultados/tablas"; r0 <- 0.921   # G (ii), todas M3/M1 a >= 36 °C (referencia fijada en la especificación)
terc <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)]
q <- merge(fread("datos/derivados/tmax_percentiles_municipio.csv"), terc, by = "cve")
desc <- q[, .(municipios = .N, p99_mediana = median(p99), p75_mediana = median(p75), pct_p99_mayor_36 = 100 * mean(p99 >= 36)), by = marg][order(marg)]
cat("Percentiles locales de Tmax por tercil de marginación:\n"); print(desc[, lapply(.SD, function(v) round(v, 2))])
# descriptivo de interpretación (añadido tras ver el criterio; no entra en él): ¿dónde caen y qué tan calientes
# son los días >= 36 °C de cada tercil? Dosis dentro del bin abierto y lo común que es 36 °C en el municipio.
suppressMessages(library(arrow))
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_rel_2012_2025.parquet", col_select = c("cve", "fecha", "tmax", "bin")))[fecha <= as.IDate("2024-12-31")]
cl <- merge(cl, terc, by = "cve")
cl[, frac36 := mean(tmax >= 36), by = cve]
d36 <- cl[tmax >= 36, .(dias_ge36 = .N, municipios = uniqueN(cve), tmax_mediana = median(tmax), tmax_p90 = quantile(tmax, 0.9),
                        pct_ge38 = 100 * mean(tmax >= 38), pct_ge40 = 100 * mean(tmax >= 40),
                        frac36_local_mediana = 100 * median(frac36), pct_en_p99_local = 100 * mean(bin == 10L), pct_bajo_p95_local = 100 * mean(bin <= 7L)), by = marg][order(marg)]
cat("\nDías con Tmax >= 36 °C por tercil (2012-2024):\n"); print(d36[, lapply(.SD, function(v) round(v, 2))])
fwrite(merge(desc, d36, by = "marg"), file.path(T, "mortalidad_aclimatacion_descriptivos_2012_2025.csv"))

dir_de <- function(cp, k) sprintf("%s/rezagos_defunciones%s%s_expo-rel", T, if (cp == "todas_65mas") "_edad" else "", if (is.na(k)) "" else paste0("_marg", k))
caps <- c("todas", "circulatorio", "todas_65mas")
cur <- rbindlist(lapply(caps, function(cp) rbindlist(lapply(c(NA, 1:3), function(k)
  fread(file.path(dir_de(cp, k), sprintf("2012_2025_%s.csv", cp)))[cantidad == "acumulado_0_14", .(cap, bin, coef, se, irr, irr_lo, irr_hi)][, marg := k]))))
stopifnot(!anyNA(cur$coef))
fwrite(cur, file.path(T, "mortalidad_aclimatacion_curvas_2012_2025.csv"))
cat("\nNacional, acumulado 0-14 frente a [25,75):\n")
print(dcast(cur[is.na(marg)], bin ~ cap, value.var = "irr")[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)])

coc <- dcast(cur[!is.na(marg) & bin %in% c("[97.5,99)", "[99,100]")], cap + bin ~ marg, value.var = c("coef", "se"))
coc[, `:=`(T1 = exp(coef_1), T2 = exp(coef_2), T3 = exp(coef_3), ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
coc[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)), ancho_log = 2 * 1.96 * se_r)]
coc[bin == "[99,100]", q := p.adjust(p, "BH")]   # BH sobre los 3 cocientes del contraste principal
coc[, parte := fifelse(bin == "[99,100]", "L-a principal", "L-a secundario")]
out <- coc[, .(parte, cap, bin, T1, T2, T3, ratio, lo, hi, p, q, ancho_log)]
setorder(out, -parte, cap)
fwrite(out, file.path(T, "mortalidad_aclimatacion_2012_2025.csv"))
cat("\nCocientes M3/M1 (acumulado 0-14 frente a [25,75)):\n")
print(out[, lapply(.SD, function(v) if (is.numeric(v)) signif(v, 3) else v)])

x <- out[parte == "L-a principal" & cap == "todas"]
stopifnot(nrow(x) == 1, !is.null(x$ancho_log))
v <- if (x$lo <= 1 && x$hi >= 1 && abs(log(x$ratio)) < abs(log(r0))) "EXPLICA el gradiente" else
     if (x$hi < 1 && x$ancho_log < 0.4) "NO explica el gradiente" else
     if (x$lo > 1) "INVERSIÓN (M3 más afectado por un día localmente extremo)" else "INDETERMINADO"
cat(sprintf("\nL-a: todas a [99,100] M3/M1 %.3f [%.3f, %.3f] (referencia absoluta %.3f) -> aclimatación: %s\n", x$ratio, x$lo, x$hi, r0, v))
