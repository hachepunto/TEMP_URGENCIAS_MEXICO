#!/usr/bin/env Rscript
# Extrae de las tablas del pipeline todas las cifras que cita el borrador del manuscrito (v0.2 en adelante)
# y las escribe en un solo archivo. Cada bloque dice de qué tabla sale. Regla del proyecto: ninguna cifra
# del borrador se escribe de memoria; se copia de aquí.
# Salida: resultados/tablas/cifras_manuscrito_2012_2025.md
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
T <- "resultados/tablas"; p <- "2012_2025"
L <- character(); out <- function(...) L <<- c(L, sprintf(...))
tab <- function(x, titulo, fuente) { out("\n### %s\n\nFuente: `%s`\n", titulo, fuente)
  L <<- c(L, paste0("| ", paste(names(x), collapse = " | "), " |"), paste0("|", strrep("---|", ncol(x))),
          apply(x, 1, function(r) paste0("| ", paste(trimws(r), collapse = " | "), " |"))) }
f3 <- function(v) sprintf("%.3f", v); ci <- function(e, lo, hi) sprintf("%.3f [%.3f, %.3f]", e, lo, hi)
sig <- function(lo, hi) fifelse(lo > 1, "sube", fifelse(hi < 1, "baja", "nulo"))
out("# Cifras del manuscrito — generado por 30_cifras_manuscrito.R el %s", format(Sys.time(), "%Y-%m-%d %H:%M"))

# --- muestra y exposición ---
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet", col_select = c("cve", "fecha", "bin")))
cl <- cl[!(fecha >= as.IDate("2012-12-26") & fecha <= as.IDate("2013-12-25"))]
out("\n## Muestra y exposición (clima_ventanas_2012_2025.parquet, sin 2012-12-26..2013-12-25)\n")
out("- municipios: %d; días: %d; municipio-días por desenlace: %s", uniqueN(cl$cve), uniqueN(cl$fecha), format(nrow(cl), big.mark = ","))
out("- municipio-días con Tmax >= 36: %.2f%%; municipios que nunca llegan a >= 36: %d", 100 * mean(cl$bin == 10L), cl[, .(n = sum(bin == 10L)), by = cve][n == 0, .N])
out("- municipio-días con Tmax < 12: %.2f%%", 100 * mean(cl$bin == 1L))
terc <- fread("datos/derivados/marginacion_terciles_2020.csv")
cl <- merge(cl, terc[, .(cve, tercil)], by = "cve")
x <- cl[, .(pct_ge36 = round(100 * mean(bin == 10L), 2)), by = tercil][order(tercil)]
out("- %% de días >= 36 por tercil de marginación: %s", paste(sprintf("M%d %.2f", x$tercil, x$pct_ge36), collapse = "; "))
rh <- fread(file.path(T, "residencia_vs_hospital.csv")); tab(rh, "Atenciones fuera del municipio de residencia", "residencia_vs_hospital.csv")

# --- tabla 1 ---
r <- fread(file.path(T, sprintf("rezagos_%s.csv", p)))
a <- r[bin == "[36, Inf)" & cantidad %in% c("v0", "acumulado_0_14")]
w <- dcast(a, cap ~ cantidad, value.var = c("irr", "irr_lo", "irr_hi", "irr_lo_2way", "irr_hi_2way"))
setorder(w, -irr_acumulado_0_14)
tab(w[, .(cap, mismo_dia = f3(irr_v0), acumulado_0_14 = ci(irr_acumulado_0_14, irr_lo_acumulado_0_14, irr_hi_acumulado_0_14),
          ic_bidireccional = sprintf("[%.3f, %.3f]", irr_lo_2way_acumulado_0_14, irr_hi_2way_acumulado_0_14),
          signo = sig(irr_lo_acumulado_0_14, irr_hi_acumulado_0_14))], "Tabla 1: >= 36 °C vs 24-27 °C", sprintf("rezagos_%s.csv", p))
w2 <- w[cap != "total"]
out("\n- capítulos que suben / bajan / nulos (acumulado, IC por municipio): %d / %d / %d",
    w2[irr_lo_acumulado_0_14 > 1, .N], w2[irr_hi_acumulado_0_14 < 1, .N], w2[irr_lo_acumulado_0_14 <= 1 & irr_hi_acumulado_0_14 >= 1, .N])
anch <- w[, (irr_hi_2way_acumulado_0_14 - irr_lo_2way_acumulado_0_14) / (irr_hi_acumulado_0_14 - irr_lo_acumulado_0_14) - 1]
out("- ensanchamiento del IC bidireccional: %.0f%% a %.0f%%; cambios de significancia: %d", 100 * min(anch), 100 * max(anch),
    w[, sum(sig(irr_lo_acumulado_0_14, irr_hi_acumulado_0_14) != sig(irr_lo_2way_acumulado_0_14, irr_hi_2way_acumulado_0_14))])
fr <- r[bin == "[-Inf,12)" & cantidad == "acumulado_0_14"][order(irr)]
tab(fr[, .(cap, acumulado_menos12 = ci(irr, irr_lo, irr_hi))], "Frío < 12 °C, acumulado 0-14 (principal)", sprintf("rezagos_%s.csv", p))

# curvas: monotonía del acumulado desde 27 °C
niv <- c("[24,27)", "[27,30)", "[30,33)", "[33,36)", "[36, Inf)")
cu <- r[cantidad == "acumulado_0_14" & bin %in% niv][, bin := factor(bin, levels = niv)][order(cap, bin)]
mono <- cu[, .(creciente = all(diff(irr) > 0), decreciente = all(diff(irr) < 0), bin_max = as.character(bin[which.max(irr)])), by = cap]
tab(mono, "Forma de la curva acumulada de 24-27 a >= 36 °C", sprintf("rezagos_%s.csv", p))

# dinámica: ventanas posteriores
din <- r[bin == "[36, Inf)" & cantidad %in% c("v0", "v1_3", "v4_7", "v8_14")]
din <- dcast(din, cap ~ cantidad, value.var = c("irr", "irr_lo", "irr_hi"))
din[, `:=`(algun_tardio_bajo = irr_hi_v1_3 < 1 | irr_hi_v4_7 < 1 | irr_hi_v8_14 < 1, algun_tardio_alto = irr_lo_v1_3 > 1 | irr_lo_v4_7 > 1 | irr_lo_v8_14 > 1)]
din <- merge(din, w[, .(cap, irr_acum = irr_acumulado_0_14, lo_acum = irr_lo_acumulado_0_14, hi_acum = irr_hi_acumulado_0_14)], by = "cap")
din[, patron := fifelse(irr_hi_v0 < 1 & !algun_tardio_alto, "baja sin rebote",
                fifelse(!algun_tardio_bajo, "exceso neto",
                fifelse(lo_acum > 1, "adelanto parcial", fifelse(hi_acum < 1, "caída tardía mayor que el exceso", "adelanto que anula el exceso"))))]
tab(din[, .(cap, v0 = f3(irr_v0), v1_3 = f3(irr_v1_3), v4_7 = f3(irr_v4_7), v8_14 = f3(irr_v8_14), acumulado = f3(irr_acum), patron)][order(patron, cap)],
    "Dinámica por ventana a >= 36 °C (IRR por día de rezago)", sprintf("rezagos_%s.csv", p))

# --- subgrupos ---
s <- fread(file.path(T, sprintf("rezagos_subgrupos_%s.csv", p)))[bin %in% c("[30,33)", "[33,36)", "[36, Inf)")]
tab(s[, .(cap, cantidad, bin, irr = ci(irr, irr_lo, irr_hi))][order(cap, bin, cantidad)], "Subgrupos E86 / N17 / I21", sprintf("rezagos_subgrupos_%s.csv", p))

# --- hospital ---
h <- fread(file.path(T, sprintf("rezagos_hospital_%s.csv", p)))[cantidad == "acumulado_0_14" & bin == "[36, Inf)", .(cap, hosp = irr)]
h <- merge(w[, .(cap, res = irr_acumulado_0_14)], h, by = "cap")[, dif := hosp - res][order(-abs(dif))]
tab(h[, .(cap, residencia = f3(res), hospital = f3(hosp), dif = sprintf("%+.3f", dif))], "Residencia vs hospital, acumulado >= 36", sprintf("rezagos_hospital_%s.csv", p))

# --- D, E ---
m <- fread(file.path(T, sprintf("marginacion_%s.csv", p)))
tab(m[, .(cap, tercil, irr = ci(irr, irr_lo, irr_hi), M3_vs_M1 = ci(ratio_3vs1, ratio_lo, ratio_hi))], "D: terciles de marginación, >= 36", sprintf("marginacion_%s.csv", p))
e <- unique(fread(file.path(T, sprintf("clima_marg_%s.csv", p)))[!is.na(ratio_3vs1), .(cap, clima, bin, M3_vs_M1 = ci(ratio_3vs1, ratio_lo, ratio_hi), excluye_1 = ratio_lo > 1 | ratio_hi < 1)])
tab(e[order(bin, cap, clima)], "E: M3 vs M1 a clima de base constante", sprintf("clima_marg_%s.csv", p))
e2 <- fread(file.path(T, sprintf("clima_marg_%s.csv", p)))[bin == "[36, Inf)" & !is.na(irr)]
tab(dcast(e2, cap + marg ~ clima, value.var = "irr", fun.aggregate = function(v) round(v[1], 3)), "E: IRR >= 36 por clima (columnas C) y marginación", sprintf("clima_marg_%s.csv", p))
cel <- fread(file.path(T, "celdas_clima_marg.csv")); tab(cel, "Tamaño de celdas clima × marginación", "celdas_clima_marg.csv")

# --- A ---
a2 <- fread(file.path(T, sprintf("rezagos_fe-anio_semana_%s.csv", p)))[cantidad == "acumulado_0_14" & bin %in% c("[36, Inf)", "[-Inf,12)")]
tab(a2[, .(cap, bin, irr = ci(irr, irr_lo, irr_hi))][order(bin, cap)], "A: efectos fijos mun×año + edo×semana + edo×dow", sprintf("rezagos_fe-anio_semana_%s.csv", p))

# --- sin 2012, 30 días ---
d14 <- fread(file.path(T, sprintf("rezagos_desde2014_%s.csv", p)))[cantidad == "acumulado_0_14" & bin == "[36, Inf)", .(cap, desde2014 = irr)]
d14 <- merge(w[, .(cap, base = irr_acumulado_0_14)], d14, by = "cap")[, dif := desde2014 - base]
out("\n- sin 2012 (desde 2014): máx |dif| acumulado >= 36 = %.3f (%s); cambios de signo/significancia ver tabla", max(abs(d14$dif)), d14[which.max(abs(dif)), cap])
v30 <- fread(file.path(T, sprintf("rezagos_v30_%s.csv", p)))[bin == "[36, Inf)" & cantidad %in% c("acumulado_0_14", "acumulado_0_30")]
tab(dcast(v30[, .(cap, cantidad, v = ci(irr, irr_lo, irr_hi))], cap ~ cantidad, value.var = "v"), "Ventanas a 30 días, >= 36", sprintf("rezagos_v30_%s.csv", p))

# --- H: códigos ---
cf <- fread(file.path(T, sprintf("codigos_fdr_%s.csv", p)))[preespecificado == TRUE]
for (ct in c("calor_36", "frio_12")) {
  y <- cf[contraste == ct]
  out("\n- H %s: %d/%d con q < 0.05 (%d suben, %d bajan); controles Z con q < 0.05: %d/%d", ct, sum(y$sig), nrow(y), sum(y$sig & y$beta > 0), sum(y$sig & y$beta < 0),
      sum(y$sig & y$capitulo == "Z_control"), sum(y$capitulo == "Z_control"))
  tab(y[sig == TRUE][order(-irr_post), .(cie3, capitulo, nombre = substr(nombre, 1, 45), irr = ci(irr, irr_lo, irr_hi), irr_contraido = f3(irr_post), q = signif(q, 2))],
      sprintf("H: códigos con q < 0.05, %s", ct), sprintf("codigos_fdr_%s.csv", p))
}
z <- cf[contraste == "calor_36" & capitulo == "Z_control"][order(q)]
tab(z[, .(cie3, nombre = substr(nombre, 1, 45), irr = ci(irr, irr_lo, irr_hi), q = signif(q, 2))], "Controles negativos Z, >= 36", sprintf("codigos_fdr_%s.csv", p))
resp <- cf[contraste == "calor_36" & capitulo == "respiratorio"]
out("\n- respiratorios (J) que bajan a >= 36 con q < 0.05: %d de %d", resp[sig == TRUE & beta < 0, .N], nrow(resp))
tau <- unique(cf[contraste == "calor_36", .(capitulo, n = .N, tau = round(sqrt(tau2), 2)), by = grupo])[order(-tau)]
tab(tau, "Heterogeneidad entre códigos dentro del capítulo (tau, log-IRR calor)", sprintf("codigos_fdr_%s.csv", p))
cm <- fread(file.path(T, sprintf("codigos_marginacion_%s.csv", p)))
out("\n- H4 D: %d códigos; mediana M3/M1 %.3f; q < 0.05: %s", nrow(cm), median(cm$ratio_M3_M1),
    paste(cm[q < 0.05, sprintf("%s %.3f [%.3f, %.3f] (M1 %.2f, M3 %.2f, q %.1e)", cie3, ratio_M3_M1, lo, hi, irr_M1, irr_M3, q)], collapse = "; "))
ce <- unique(fread(file.path(T, sprintf("codigos_clima_marg_%s.csv", p)))[!is.na(ratio_M3_M1), .(cie3, clima, bin_clima, ratio_M3_M1, ratio_lo, ratio_hi, q_ratio, separacion)])
out("- H4 E: %d contrastes; separación numérica: %s; q < 0.05: %d; T63: %s", nrow(ce), paste(ce[separacion == TRUE, sprintf("%s C%d", cie3, clima)], collapse = " "),
    ce[q_ratio < 0.05, .N], paste(ce[cie3 == "T63", sprintf("C%d %.2f [%.2f, %.2f] q %.3f", clima, ratio_M3_M1, ratio_lo, ratio_hi, q_ratio)], collapse = "; "))

# --- I: humedad ---
hu <- fread(file.path(T, sprintf("humedad_comparacion_%s.csv", p)))
tab(hu[order(dbic), .(cap, dbic = round(dbic), mejor, tmax = f3(irr_tmax), at = f3(irr_at), seco = ci(irr_seco, irr_lo_seco, irr_hi_seco),
                       humedo = ci(irr_humedo, irr_lo_humedo, irr_hi_humedo), humedo_vs_seco = ci(ratio_hum_seco, ratio_lo, ratio_hi), q = signif(q, 2))],
    "I: Tmax vs temperatura aparente (BIC) y seco vs húmedo", sprintf("humedad_comparacion_%s.csv", p))
hc <- fread(file.path(T, sprintf("humedad_codigos_%s.csv", p)))
tab(hc[, .(cap, humedo = f3(`[36, Inf) humedo`), seco = f3(`[36, Inf) seco`), humedo_vs_seco = ci(ratio_hum_seco, ratio_lo, ratio_hi))], "I: códigos seco vs húmedo", sprintf("humedad_codigos_%s.csv", p))

# --- G y J: mortalidad ---
dm <- fread(file.path(T, sprintf("rezagos_defunciones_%s.csv", p)))
tab(dcast(dm[cantidad %in% c("v0", "acumulado_0_14") & bin %in% c("[-Inf,12)", "[12,15)", "[33,36)", "[36, Inf)"), .(cap, col = paste(bin, cantidad), v = ci(irr, irr_lo, irr_hi))], cap ~ col, value.var = "v"),
    "G: mortalidad por bin (acumulado y mismo día)", sprintf("rezagos_defunciones_%s.csv", p))
rs <- fread(file.path(T, sprintf("rezagos_defunciones_%s_resumen.csv", p)))
tab(rs[, .(cap, n_obs, n_mun, casos)], "G: tamaño de muestra de mortalidad", sprintf("rezagos_defunciones_%s_resumen.csv", p))
for (f in c("defunciones_marginacion_2012_2025.csv", "defunciones_clima_marg_2012_2025.csv", "mortalidad_edad_calidad_2012_2025.csv", "mortalidad_calidad_terciles_2012_2025.csv")) {
  if (!file.exists(file.path(T, f))) { out("\n(%s todavía no existe)", f); next }
  x <- fread(file.path(T, f)); num <- names(x)[sapply(x, is.numeric)]
  x[, (num) := lapply(.SD, function(v) signif(v, 3)), .SDcols = num]; tab(x, f, f)
}
writeLines(L, file.path(T, sprintf("cifras_manuscrito_%s.md", p)))
message("-> ", file.path(T, sprintf("cifras_manuscrito_%s.md", p)), " (", length(L), " líneas)")
