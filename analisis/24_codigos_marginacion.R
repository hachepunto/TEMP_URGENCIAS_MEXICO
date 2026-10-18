#!/usr/bin/env Rscript
# Especificación H4 (paso 2): marginación para los códigos que pasan el FDR de calor.
# D: cociente M3/M1 (tercil más marginado / menos marginado) del acumulado 0-14 a >= 36 °C por
#    código, con EE por delta (log-cociente = diferencia de log-IRR, estratos independientes) y BH.
# E: a clima de base constante, IRR por (clima, marginación) para los 20 códigos de mayor efecto.
# Entrada: resultados/tablas/rezagos_codigos_marg<k>/, rezagos_codigos_clima<j>_marg<k>/ (06),
#          codigos_fdr_2012_2025.csv (22)
# Salida:  resultados/tablas/codigos_marginacion_2012_2025.csv (D), codigos_clima_marg_2012_2025.csv (E),
#          resultados/figuras/codigos_marginacion_2012_2025.{pdf,png} (figura 10)
suppressMessages({library(data.table); library(ggplot2)})
periodo <- "2012_2025"
leer <- function(dir, etiqueta, bin_k = "[36, Inf)") {
  arch <- list.files(dir, sprintf("^%s_[A-Z][0-9]{2}\\.csv$", periodo), full.names = TRUE)
  if (!length(arch)) return(NULL)
  r <- rbindlist(lapply(arch, fread))[cantidad == "acumulado_0_14" & bin == bin_k, .(cie3 = cap, bin, beta = coef, se)]
  r[, estrato := etiqueta][]
}
fdr <- fread(sprintf("resultados/tablas/codigos_fdr_%s.csv", periodo))[contraste == "calor_36", .(cie3, capitulo, nombre, irr_nacional = irr, beta_post)]

# --- D ---------------------------------------------------------------------------
d <- rbindlist(lapply(1:3, function(k) leer(sprintf("resultados/tablas/rezagos_codigos_marg%d", k), paste0("M", k))))
w <- dcast(d, cie3 ~ estrato, value.var = c("beta", "se"))
w[, `:=`(log_ratio = beta_M3 - beta_M1, se_ratio = sqrt(se_M3^2 + se_M1^2))]
w[, `:=`(ratio = exp(log_ratio), lo = exp(log_ratio - 1.96 * se_ratio), hi = exp(log_ratio + 1.96 * se_ratio),
         p = 2 * pnorm(-abs(log_ratio / se_ratio)))]
w[, q := p.adjust(p, "BH")]
w <- merge(fdr, w, by = "cie3")
for (k in 1:3) w[, (paste0("irr_M", k)) := exp(get(paste0("beta_M", k)))]
setorder(w, -beta_post)
fwrite(w[, .(cie3, capitulo, nombre, irr_nacional, irr_M1, irr_M2, irr_M3, ratio_M3_M1 = ratio, lo, hi, p, q)],
       sprintf("resultados/tablas/codigos_marginacion_%s.csv", periodo))
message(sprintf("D: %d códigos; M3/M1 con q < 0.05: %d (%d con M3 > M1, %d con M3 < M1); mediana del cociente %.3f",
                nrow(w), sum(w$q < 0.05), sum(w$q < 0.05 & w$ratio > 1), sum(w$q < 0.05 & w$ratio < 1), median(w$ratio)))
print(w[q < 0.05 | abs(log_ratio) > 0.2, .(cie3, nombre = substr(nombre, 1, 36), irr_M1 = round(irr_M1, 2), irr_M3 = round(irr_M3, 2),
                                          ratio = round(ratio, 2), lo = round(lo, 2), hi = round(hi, 2), q = signif(q, 2))], nrows = 80)

# --- E ---------------------------------------------------------------------------
# Regla comprometida en la especificación E (ESPECIFICACION_sensibilidad_subgrupos.md): el bin >= 36 sólo se
# interpreta en celdas clima × marginación con >= 2,000 municipio-días en ese bin y >= 50 municipios con al
# menos uno; si no, la celda se marca «no identificada» y se usa [33,36). (Sustituye al filtro EE > 1, que
# se decidió después de ver resultados: AUDITORIA_2026-10-18, I2.)
suppressMessages(library(arrow))
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet", col_select = c("cve", "fecha", "bin")))
cl <- cl[!(fecha >= as.IDate("2012-12-26") & fecha <= as.IDate("2013-12-25"))]   # mismo recorte que 06
cl <- merge(cl, fread("datos/derivados/clima_base_terciles.csv")[, .(cve, clima)], by = "cve")
cl <- merge(cl, fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve, marg = tercil)], by = "cve")
celdas <- cl[, .(md36 = sum(bin == 10L), mun36 = uniqueN(cve[bin == 10L]), md33 = sum(bin == 9L), mun33 = uniqueN(cve[bin == 9L])), by = .(clima, marg)]
celdas[, bin_usado := fifelse(md36 >= 2000 & mun36 >= 50, "[36, Inf)", "[33,36)")]
setorder(celdas, clima, marg); print(celdas)
fwrite(celdas, sprintf("resultados/tablas/codigos_clima_marg_celdas_%s.csv", periodo))
e <- rbindlist(lapply(1:3, function(j) rbindlist(lapply(1:3, function(k)
  leer(sprintf("resultados/tablas/rezagos_codigos_clima%d_marg%d", j, k), sprintf("C%d_M%d", j, k),
       celdas[clima == j & marg == k, bin_usado])))))
if (!is.null(e) && nrow(e)) {
  e[, `:=`(clima = as.integer(substr(estrato, 2, 2)), marg = as.integer(substr(estrato, 5, 5)))]
  # el contraste M3 vs M1 sólo es válido si las dos celdas usan el mismo bin
  e[, bin_clima := if (uniqueN(bin[marg %in% c(1, 3)]) == 1) bin[1] else NA_character_, by = .(cie3, clima)]
  message(sprintf("E: %d estimaciones por celda; celdas no identificadas en >= 36 -> [33,36): %s",
                  nrow(e), paste(celdas[bin_usado != "[36, Inf)", sprintf("C%dM%d", clima, marg)], collapse = " ")))
  e <- merge(e, fdr[, .(cie3, nombre, beta_post)], by = "cie3")
  e[, `:=`(irr = exp(beta), lo = exp(beta - 1.96 * se), hi = exp(beta + 1.96 * se))]
  # dentro de cada clima: M3 vs M1
  ee <- dcast(e[!is.na(bin_clima)], cie3 + nombre + clima + bin_clima ~ marg, value.var = c("beta", "se"))
  if (!"beta_1" %in% names(ee)) ee[, `:=`(beta_1 = NA_real_, se_1 = NA_real_)]
  if (!"beta_3" %in% names(ee)) ee[, `:=`(beta_3 = NA_real_, se_3 = NA_real_)]
  ee <- ee[!is.na(beta_1) & !is.na(beta_3)]
  ee[, `:=`(ratio = exp(beta_3 - beta_1), lo = exp(beta_3 - beta_1 - 1.96 * sqrt(se_3^2 + se_1^2)),
            hi = exp(beta_3 - beta_1 + 1.96 * sqrt(se_3^2 + se_1^2)))]
  # separación numérica de Poisson (pocos casos del código en la celda): |log-IRR| > 10 (IRR > 22,000) no es
  # una estimación. Se marca y queda fuera de BH; desviación declarada de la especificación (REGISTRO 2026-10-18).
  ee[, separacion := abs(beta_1) > 10 | abs(beta_3) > 10]
  ee[, q := NA_real_]
  ee[separacion == FALSE, q := p.adjust(2 * pnorm(-abs((beta_3 - beta_1) / sqrt(se_3^2 + se_1^2))), "BH")]
  message("E: contrastes con separación numérica (fuera de BH): ", paste(ee[separacion == TRUE, sprintf("%s C%d", cie3, clima)], collapse = " "))
  fwrite(merge(e[, .(cie3, nombre, clima, marg, bin, irr, lo, hi, se)], ee[, .(cie3, clima, bin_clima, ratio_M3_M1 = ratio, ratio_lo = lo, ratio_hi = hi, q_ratio = q, separacion)],
               by = c("cie3", "clima"), all.x = TRUE), sprintf("resultados/tablas/codigos_clima_marg_%s.csv", periodo))
  message(sprintf("E: %d códigos × 9 estratos; M3/M1 con q < 0.05 dentro de clima: %d de %d", uniqueN(e$cie3), sum(ee$q < 0.05, na.rm = TRUE), sum(!ee$separacion)))
  print(ee[!is.na(q) & q < 0.05, .(cie3, nombre = substr(nombre, 1, 30), clima, bin_clima, ratio = round(ratio, 2), lo = round(lo, 2), hi = round(hi, 2))])
}

# --- figura 10: cociente M3/M1 por código (D) -------------------------------------
w[, cie3 := factor(cie3, levels = rev(cie3))]
w[, etiqueta := sprintf("%s %s", cie3, tolower(substr(nombre, 1, 34)))]
w[, sig := q < 0.05]
g <- ggplot(w, aes(ratio, cie3)) + geom_vline(xintercept = 1, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0, colour = "grey60", linewidth = 0.3) +
  geom_point(aes(colour = sig, shape = sig), size = 1.4) +
  scale_colour_manual(values = c(`TRUE` = "#c44536", `FALSE` = "grey30"), guide = "none") +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1), guide = "none") +
  scale_x_log10(breaks = c(0.5, 0.7, 1, 1.4, 2)) + coord_cartesian(xlim = c(0.4, 2.5)) +
  scale_y_discrete(labels = setNames(w$etiqueta, w$cie3)) +
  labs(x = "Cociente M3 / M1 del IRR a ≥36 °C (acumulado 0–14 d)", y = NULL,
       caption = "M1 = tercil menos marginado, M3 = más marginado (CONAPO 2020). Relleno: q < 0.05 (BH).\nCódigos con q < 0.05 en el barrido nacional de calor, ordenados por efecto.") +
  theme_minimal(base_size = 7) + theme(axis.text.y = element_text(size = 5), panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0))
h <- 1.2 + nrow(w) * 0.11
cairo_pdf(sprintf("resultados/figuras/codigos_marginacion_%s.pdf", periodo), width = 5.5, height = h); print(g); dev.off()
png(sprintf("resultados/figuras/codigos_marginacion_%s.png", periodo), width = 5.5, height = h, units = "in", res = 220); print(g); dev.off()
message("-> codigos_marginacion_", periodo, ".csv, codigos_clima_marg_", periodo, ".csv, figuras/codigos_marginacion_", periodo)
