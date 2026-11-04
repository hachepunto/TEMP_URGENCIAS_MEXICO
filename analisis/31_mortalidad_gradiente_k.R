#!/usr/bin/env Rscript
# Especificación K (ESPECIFICACION_mortalidad_gradiente_K.md): ¿el ámbito urbano/rural (K-a), algún componente
# de la marginación (K-b) o la imprecisión de las muertes sin asistencia médica (K-c) explican que el exceso de
# mortalidad por calor sea menor en el tercil más marginado? Aplica los criterios comprometidos en código.
# Entrada: datos/derivados/defunciones_2012_2024.parquet (19), componentes_imm_terciles_2020.csv (20c),
#          marginacion_terciles_2020.csv (11); resultados/tablas/rezagos_defunciones_k*_2012_2025.csv,
#          rezagos_defunciones_mun-comp_<ind>_t<k>/2012_2025_{todas,circulatorio}.csv,
#          rezagos_defunciones_marg<k>_2012_2025.csv (06)
# Salida:  resultados/tablas/mortalidad_gradiente_k_2012_2025.csv (cocientes y criterios) y
#          mortalidad_gradiente_k_descriptivos_2012_2025.csv
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
T <- "resultados/tablas"
terc <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)]
acum <- function(f, b = "[36, Inf)") fread(f)[cantidad == "acumulado_0_14" & bin == b, .(cap, coef, se)]
cociente <- function(w) {
  w[, `:=`(ratio = exp(coef_3 - coef_1), se_r = sqrt(se_1^2 + se_3^2))]
  w[, `:=`(lo = exp(log(ratio) - 1.96 * se_r), hi = exp(log(ratio) + 1.96 * se_r), p = 2 * pnorm(-abs(log(ratio) / se_r)), ancho_log = 2 * 1.96 * se_r)][]
}
leer_terciles <- function(patron, caps = NULL) {
  x <- rbindlist(lapply(1:3, function(k) {
    f <- sprintf(patron, k)
    a <- if (dir.exists(f)) rbindlist(lapply(caps, function(cp) acum(file.path(f, sprintf("2012_2025_%s.csv", cp))))) else acum(f)
    a[, t := k]
  }))
  cociente(dcast(x, cap ~ t, value.var = c("coef", "se")))
}

# --- descriptivos ---------------------------------------------------------------------
d <- as.data.table(read_parquet("datos/derivados/defunciones_2012_2024.parquet", col_select = c("ent_res", "mun_res", "asist_medi", "area_ur")))
d <- merge(d[!is.na(mun_res), .(cve = ent_res * 1000L + mun_res, asist_medi, area_ur)], terc, by = "cve")
desc <- d[, .(defunciones = .N, pct_urbano = 100 * mean(area_ur[area_ur %in% 1:2] == 1L),
              pct_sin_asistencia = 100 * mean(asist_medi[asist_medi %in% 1:2] == 2L)), by = marg][order(marg)]
cat("K descriptivos por tercil de marginación (individual):\n"); print(desc[, lapply(.SD, function(v) round(v, 2))])
comp <- fread("datos/derivados/componentes_imm_terciles_2020.csv")
ind <- c("PL.5000", "VHAC", "OVPT", "OVSEE", "PO2SM")
cm <- cor(comp[, c(list(marginacion = -IM_2020), .SD), .SDcols = ind], method = "spearman")
cat("\nK-b: correlaciones de Spearman (marginacion = -IM_2020, mayor = más marginado):\n"); print(round(cm, 2))
cruce <- merge(comp[, c("cve", paste0("t_", ind)), with = FALSE], terc, by = "cve")
coincid <- rbindlist(lapply(ind, function(v) data.table(indicador = v, pct_T3_en_M3 = 100 * cruce[get(paste0("t_", v)) == 3, mean(marg == 3)],
                                                       pct_T1_en_M1 = 100 * cruce[get(paste0("t_", v)) == 1, mean(marg == 1)])))
cat("\nK-b: coincidencia de terciles con los de marginación:\n"); print(coincid[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 1) else v)])
fwrite(rbind(desc[, .(nivel = paste0("M", marg), variable = "pct_urbano", valor = pct_urbano)],
             desc[, .(nivel = paste0("M", marg), variable = "pct_sin_asistencia", valor = pct_sin_asistencia)],
             coincid[, .(nivel = indicador, variable = "pct_T3_en_M3", valor = pct_T3_en_M3)],
             coincid[, .(nivel = indicador, variable = "pct_T1_en_M1", valor = pct_T1_en_M1)],
             as.data.table(as.table(cm))[, .(nivel = paste(V1, V2, sep = "~"), variable = "spearman", valor = N)]),
       file.path(T, "mortalidad_gradiente_k_descriptivos_2012_2025.csv"))

# --- referencia G (ii) -------------------------------------------------------------------
ref <- leer_terciles(file.path(T, "rezagos_defunciones_marg%d_2012_2025.csv"))[cap %in% c("todas", "circulatorio")]
ref[, `:=`(q = NA_real_, parte = "G (ii) referencia")]
r0 <- ref[cap == "todas", ratio]

# --- K-a y K-c ---------------------------------------------------------------------------
nac <- acum(file.path(T, "rezagos_defunciones_k_2012_2025.csv"))
nac[, `:=`(irr = exp(coef), lo = exp(coef - 1.96 * se), hi = exp(coef + 1.96 * se))]
cat("\nK-a/K-c nacional, acumulado 0-14 a >= 36:\n"); print(nac[, .(cap, irr = round(irr, 3), lo = round(lo, 3), hi = round(hi, 3))])
kac <- leer_terciles(file.path(T, "rezagos_defunciones_k_marg%d_2012_2025.csv"))
ka <- kac[grepl("urbano|rural", cap)][, `:=`(q = p.adjust(p, "BH"), parte = "K-a ámbito")]
kc <- kac[grepl("asist", cap)][, `:=`(q = p.adjust(p, "BH"), parte = "K-c asistencia")]

# --- K-b ---------------------------------------------------------------------------------
kb <- rbindlist(lapply(sub("\\.", "", ind), function(v)
  leer_terciles(file.path(T, paste0("rezagos_defunciones_mun-comp_", v, "_t%d")), c("todas", "circulatorio"))[, indicador := v]))
kb[, `:=`(q = p.adjust(p, "BH"), parte = "K-b componentes")]
kb[, cap := paste(indicador, cap, sep = ":")]

out <- rbind(ref, ka, kb, kc, fill = TRUE)
out[, `:=`(T1 = exp(coef_1), T2 = exp(coef_2), T3 = exp(coef_3))]
fwrite(out[, .(parte, cap, T1, T2, T3, ratio, lo, hi, p, q, ancho_log)], file.path(T, "mortalidad_gradiente_k_2012_2025.csv"))
cat("\nCocientes T3/T1 (M3/M1), acumulado 0-14 a >= 36 °C:\n")
print(out[, .(parte, cap, T1 = round(T1, 3), T2 = round(T2, 3), T3 = round(T3, 3), ratio = round(ratio, 3), lo = round(lo, 3), hi = round(hi, 3), q = signif(q, 2))])

# --- criterios comprometidos ------------------------------------------------------------
cerca <- function(r) abs(log(r)) < abs(log(r0))
a1 <- nac[cap == "todas_urbano", irr] > nac[cap == "todas_rural", irr]
ka_t <- ka[cap %in% c("todas_urbano", "todas_rural")]
a2 <- all(ka_t$lo <= 1 & ka_t$hi >= 1 & cerca(ka_t$ratio))
stopifnot(!is.null(ka_t$ancho_log)); a_no <- any(ka_t$ancho_log < 0.4 & ka_t$hi < 1)
cat(sprintf("\nK-a: (i) efecto urbano > rural: %s; (ii) M3/M1 incluye 1 y más cerca de 1 que %.3f en ambos ámbitos: %s; algún ámbito informativo con IC < 1: %s -> ámbito: %s\n",
            a1, r0, a2, a_no, if (a1 && a2) "EXPLICA el gradiente" else if (a_no) "NO explica el gradiente" else "INDETERMINADO"))
sig <- kb[grepl(":todas$", cap), .(indicador, s = ratio < 1 & q < 0.05)]
s <- setNames(sig$s, sig$indicador); viv <- any(s[c("VHAC", "OVPT", "OVSEE")])
lect <- if (s["PL5000"] && !viv) "ruralidad" else if (viv && !s["PL5000"]) "vivienda" else "no separable"
cat(sprintf("K-b: T3/T1 todas < 1 con q < 0.05: %s -> lectura: %s\n", paste(sprintf("%s=%s", names(s), s), collapse = " "), lect))
if (s["OVSEE"]) cat("K-b: OVSEE T3/T1 < 1 contradice la hipótesis de enfriamiento (declarado de antemano)\n")
rc <- kc[cap == "todas_conasist"]
c_si <- rc$lo <= 1 & rc$hi >= 1 & cerca(rc$ratio); c_no <- rc$hi < 1
cat(sprintf("K-c: M3/M1 con asistencia %.3f [%.3f, %.3f] -> imprecisión sin asistencia: %s\n",
            rc$ratio, rc$lo, rc$hi, if (c_si) "EXPLICA el gradiente" else if (c_no) "NO explica el gradiente" else "INDETERMINADO"))
