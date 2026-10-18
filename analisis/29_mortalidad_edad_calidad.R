#!/usr/bin/env Rscript
# Especificación J (ESPECIFICACION_mortalidad_marginacion.md): ¿la edad (J-a) o la calidad del registro
# (J-b) explican que el exceso de mortalidad por calor sea menor en el tercil más marginado?
# Entrada: datos/derivados/defunciones_2012_2024.parquet, calidad_defunciones_municipio.csv,
#          municipios_registro_bueno.txt, marginacion_terciles_2020.csv (11);
#          resultados/tablas/rezagos_defunciones_edad*_2012_2025.csv,
#          rezagos_defunciones_marg<k>_mun-municipios_registro_bueno_2012_2025.csv (06)
# Salida:  resultados/tablas/mortalidad_edad_calidad_2012_2025.csv (cocientes) y
#          mortalidad_calidad_terciles_2012_2025.csv (descriptivos)
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
T <- "resultados/tablas"
terc <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)]
acum <- function(f, b = "[36, Inf)") fread(f)[cantidad == "acumulado_0_14" & bin == b, .(cap, coef, se)]
cociente <- function(w) {
  w[, `:=`(ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
  w[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)))][]
}

# --- descriptivos por tercil -------------------------------------------------------
d <- as.data.table(read_parquet("datos/derivados/defunciones_2012_2024.parquet", col_select = c("ent_res", "mun_res", "edad_anios")))
d <- merge(d[!is.na(mun_res), .(cve = ent_res * 1000L + mun_res, edad_anios)], terc, by = "cve")
edad <- d[, .(defunciones = .N, pct_65mas = 100 * mean(edad_anios >= 65, na.rm = TRUE), edad_mediana = as.numeric(median(edad_anios, na.rm = TRUE))), by = marg]
q <- merge(fread("datos/derivados/calidad_defunciones_municipio.csv"), terc, by = "cve")
cal <- q[, .(municipios = .N,
             fecha_incompleta_agregado = weighted.mean(pct_fecha_incompleta, defunciones), fecha_incompleta_mediana = median(pct_fecha_incompleta),
             tardio_agregado = weighted.mean(pct_registro_tardio, defunciones), tardio_mediana = median(pct_registro_tardio),
             sin_asistencia_agregado = weighted.mean(pct_sin_asistencia, defunciones), sin_asistencia_mediana = median(pct_sin_asistencia),
             edad_ne_agregado = weighted.mean(pct_edad_ne, defunciones)), by = marg]
buenos <- as.integer(readLines("datos/derivados/municipios_registro_bueno.txt"))
cal <- merge(cal, terc[, .(buena_calidad = sum(cve %in% buenos), total = .N), by = marg][, .(marg, pct_mun_buena_calidad = 100 * buena_calidad / total)], by = "marg")
desc <- merge(edad, cal, by = "marg"); setorder(desc, marg)
fwrite(desc, file.path(T, "mortalidad_calidad_terciles_2012_2025.csv"))
cat("Descriptivos por tercil de marginación (M1 menos, M3 más marginado):\n"); print(desc[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 2) else v)])

# --- J-a: edad ---------------------------------------------------------------------
nac <- acum(file.path(T, "rezagos_defunciones_edad_2012_2025.csv"))
nac[, `:=`(irr = exp(coef), lo = exp(coef - 1.96 * se), hi = exp(coef + 1.96 * se))]
cat("\nJ-a nacional, acumulado 0-14 a >= 36 por grupo de edad:\n"); print(nac[, .(cap, irr = round(irr, 3), lo = round(lo, 3), hi = round(hi, 3))])
ja <- rbindlist(lapply(1:3, function(k) acum(file.path(T, sprintf("rezagos_defunciones_edad_marg%d_2012_2025.csv", k)))[, marg := k]))
ja <- cociente(dcast(ja, cap ~ marg, value.var = c("coef", "se")))
ja[, q := p.adjust(p, "BH")]
ja[, parte := "J-a edad"]

# --- J-b: municipios de registro de buena calidad ------------------------------------
# sólo 2 desenlaces por corrida: 06 no junta la tabla, se leen los archivos por desenlace
jb <- rbindlist(lapply(1:3, function(k) rbindlist(lapply(c("todas", "circulatorio"), function(cp)
  acum(file.path(T, sprintf("rezagos_defunciones_marg%d_mun-municipios_registro_bueno/2012_2025_%s.csv", k, cp)))))[, marg := k]))
jb <- cociente(dcast(jb, cap ~ marg, value.var = c("coef", "se")))
jb[, q := p.adjust(p, "BH")]
jb[, parte := "J-b registro bueno"]
ref <- rbindlist(lapply(1:3, function(k) acum(file.path(T, sprintf("rezagos_defunciones_marg%d_2012_2025.csv", k)))[cap %in% c("todas", "circulatorio")][, marg := k]))
ref <- cociente(dcast(ref, cap ~ marg, value.var = c("coef", "se")))[, `:=`(q = NA_real_, parte = "G (ii) referencia, todos los municipios")]

out <- rbind(ref, ja, jb, fill = TRUE)
out[, `:=`(M1 = exp(coef_1), M2 = exp(coef_2), M3 = exp(coef_3))]
fwrite(out[, .(parte, cap, M1, M2, M3, ratio, lo, hi, p, q)], file.path(T, "mortalidad_edad_calidad_2012_2025.csv"))
cat("\nCocientes M3/M1, acumulado 0-14 a >= 36 °C:\n")
print(out[, .(parte, cap, M1 = round(M1, 3), M2 = round(M2, 3), M3 = round(M3, 3), ratio = round(ratio, 3), lo = round(lo, 3), hi = round(hi, 3), q = signif(q, 2))])

# --- criterios comprometidos ----------------------------------------------------------
r65 <- ja[cap == "todas_65mas"]; rc <- ref[cap == "todas"]
a1 <- nac[cap == "todas_65mas", irr] > nac[cap == "todas_menos65", irr]
a2 <- r65$lo <= 1 & r65$hi >= 1 & abs(log(r65$ratio)) < abs(log(rc$ratio))
cat(sprintf("\nJ-a: (i) efecto mayor en >= 65: %s; (ii) M3/M1 en >= 65 incluye 1 y más cerca de 1 que %.3f: %s -> la edad %s el gradiente\n",
            a1, rc$ratio, a2, if (a1 && a2) "EXPLICA" else "NO explica"))
b1 <- desc[marg == 3, fecha_incompleta_agregado] > desc[marg == 1, fecha_incompleta_agregado] |
      desc[marg == 3, tardio_agregado] > desc[marg == 1, tardio_agregado]
rb <- jb[cap == "todas"]; b2 <- rb$lo <= 1 & rb$hi >= 1
cat(sprintf("J-b: (i) M3 con peor registro que M1: %s; (ii) M3/M1 en buena calidad incluye 1: %s (%.3f [%.3f, %.3f]) -> la calidad %s el gradiente\n",
            b1, b2, rb$ratio, rb$lo, rb$hi, if (b1 && b2) "EXPLICA" else "NO explica"))
