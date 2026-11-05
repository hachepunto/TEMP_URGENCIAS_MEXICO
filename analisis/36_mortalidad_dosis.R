#!/usr/bin/env Rscript
# Especificación L-a2 (ESPECIFICACION_dosis_L-a2.md): con el bin >= 36 °C partido en 36-38, 38-40 y >= 40,
# ¿el exceso de mortalidad sigue siendo menor en el tercil más marginado a la misma temperatura absoluta?
# Aplica el criterio comprometido en código.
# Entrada: datos/derivados/clima_ventanas_fino_2012_2025.parquet (35), marginacion_terciles_2020.csv (11);
#          resultados/tablas/rezagos_defunciones[_edad][_marg<k>]_expo-fino/2012_2025_<cap>.csv (06, EXPO=fino)
# Salida:  resultados/tablas/mortalidad_dosis_2012_2025.csv (cocientes M3/M1 y criterio),
#          mortalidad_dosis_curvas_2012_2025.csv (IRR acumulado 0-14 por bin, nacional y por tercil),
#          mortalidad_dosis_descriptivos_2012_2025.csv (días y mediana de Tmax por bin >= 36 y tercil)
suppressMessages({library(data.table); library(arrow)})
T <- "resultados/tablas"; r0 <- 0.921   # G (ii), todas M3/M1 a >= 36 °C (referencia fijada en la especificación)
altos <- c("[36,38)", "[38,40)", "[40, Inf)")
terc <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)]
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_fino_2012_2025.parquet", col_select = c("cve", "fecha", "tmax", "bin")))[fecha <= as.IDate("2024-12-31") & bin >= 10L]
cl <- merge(cl, terc, by = "cve")
desc <- cl[, .(dias = .N, municipios = uniqueN(cve), tmax_mediana = median(tmax)), by = .(marg, bin = altos[bin - 9L])][order(bin, marg)]
cat("Días con Tmax >= 36 °C por bin y tercil (2012-2024):\n"); print(desc[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 2) else v)])
fwrite(desc, file.path(T, "mortalidad_dosis_descriptivos_2012_2025.csv"))

dir_de <- function(cp, k) sprintf("%s/rezagos_defunciones%s%s_expo-fino", T, if (cp == "todas_65mas") "_edad" else "", if (is.na(k)) "" else paste0("_marg", k))
caps <- c("todas", "circulatorio", "todas_65mas")
cur <- rbindlist(lapply(caps, function(cp) rbindlist(lapply(c(NA, 1:3), function(k)
  fread(file.path(dir_de(cp, k), sprintf("2012_2025_%s.csv", cp)))[cantidad == "acumulado_0_14", .(cap, bin, coef, se, irr, irr_lo, irr_hi)][, marg := k]))))
stopifnot(!anyNA(cur$coef), all(altos %in% cur$bin))
fwrite(cur, file.path(T, "mortalidad_dosis_curvas_2012_2025.csv"))
cat("\nNacional, acumulado 0-14 frente a [24,27):\n")
print(dcast(cur[is.na(marg)], bin ~ cap, value.var = "irr")[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)])

coc <- dcast(cur[!is.na(marg) & bin %in% altos], cap + bin ~ marg, value.var = c("coef", "se"))
coc[, `:=`(T1 = exp(coef_1), T2 = exp(coef_2), T3 = exp(coef_3), ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
coc[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)), ancho_log = 2 * 1.96 * se_r)]
coc[bin == "[36,38)", q := p.adjust(p, "BH")]   # BH sobre los 3 cocientes del contraste principal
coc[, parte := fifelse(bin == "[36,38)", "L-a2 principal", "L-a2 secundario")]
coc[, bin := factor(bin, altos)]
out <- coc[, .(parte, cap, bin, T1, T2, T3, ratio, lo, hi, p, q, ancho_log)]
setorder(out, -parte, cap, bin)
fwrite(out, file.path(T, "mortalidad_dosis_2012_2025.csv"))
cat("\nCocientes M3/M1 (acumulado 0-14 frente a [24,27)):\n")
print(out[, lapply(.SD, function(v) if (is.numeric(v)) signif(v, 3) else v)])

x <- out[parte == "L-a2 principal" & cap == "todas"]
stopifnot(nrow(x) == 1, !is.null(x$ancho_log))
v <- if (x$lo <= 1 && x$hi >= 1 && abs(log(x$ratio)) < abs(log(r0))) "DOSIS (el gradiente desaparece a igual temperatura)" else
     if (x$hi < 1 && x$ancho_log < 0.4) "PERSISTE (ni dosis ni aclimatación lo explican)" else
     if (x$lo > 1) "ACLIMATACIÓN NETA de M1 (M3 más afectado a igual temperatura)" else "INDETERMINADO"
cat(sprintf("\nL-a2: todas a [36,38) M3/M1 %.3f [%.3f, %.3f] (ancho log %.2f; referencia %.3f) -> %s\n", x$ratio, x$lo, x$hi, x$ancho_log, r0, v))
