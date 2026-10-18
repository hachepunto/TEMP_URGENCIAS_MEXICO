#!/usr/bin/env Rscript
# Especificación I: comparación Tmax vs temperatura aparente (I1, BIC y acumulado >= 36) y calor seco vs
# húmedo (I2, diferencia de log-IRR húmedo - seco en [36, Inf) con covarianza completa, BH sobre los 16
# capítulos). Figura 11.
# Entrada: resultados/tablas/rezagos_2012_2025{,_resumen}.csv (EXPO=tmax, con bic),
#          rezagos_expo-at_2012_2025{,_resumen}.csv, rezagos_expo-hum_2012_2025.csv,
#          rezagos_expo-hum/2012_2025_<cap>_vcov.rds (06), rezagos_codigos_expo-hum/ (códigos, exploratorio)
# Salida:  resultados/tablas/humedad_comparacion_2012_2025.csv, resultados/figuras/humedad_2012_2025.{pdf,png}
suppressMessages({library(data.table); library(ggplot2); library(grid)})
p <- "2012_2025"; acum <- "acumulado_0_14"
ventanas <- c(v0 = 1, v1_3 = 3, v4_7 = 4, v8_14 = 7)

# --- I1: BIC y acumulado >= 36, Tmax vs AT -----------------------------------------
rt <- fread(sprintf("resultados/tablas/rezagos_%s_resumen.csv", p));            ra <- fread(sprintf("resultados/tablas/rezagos_expo-at_%s_resumen.csv", p))
stopifnot("bic" %in% names(rt), all(rt$n_obs == ra[match(rt$cap, cap), n_obs]))   # misma muestra
i1 <- merge(rt[, .(cap, bic_tmax = bic)], ra[, .(cap, bic_at = bic)], by = "cap")
i1[, dbic := bic_at - bic_tmax][, mejor := fifelse(dbic <= -10, "AT", fifelse(dbic >= 10, "Tmax", "igual"))]
ct <- fread(sprintf("resultados/tablas/rezagos_%s.csv", p))[cantidad == acum & bin == "[36, Inf)", .(cap, irr_tmax = irr, lo_tmax = irr_lo, hi_tmax = irr_hi)]
ca <- fread(sprintf("resultados/tablas/rezagos_expo-at_%s.csv", p))[cantidad == acum & bin == "[36, Inf)", .(cap, irr_at = irr, lo_at = irr_lo, hi_at = irr_hi)]
i1 <- Reduce(function(a, b) merge(a, b, by = "cap"), list(i1, ct, ca))
message("I1: BIC mejor con AT en ", sum(i1$mejor == "AT"), ", con Tmax en ", sum(i1$mejor == "Tmax"), ", igual en ", sum(i1$mejor == "igual"), " de ", nrow(i1))

# --- I2: húmedo - seco en [36, Inf), con covarianza completa -----------------------
niv_h <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)", "[27,30)", "[30,33)",
           "[33,36) seco", "[33,36) humedo", "[36, Inf) seco", "[36, Inf) humedo")
contraste <- function(dir, cp) {
  V <- readRDS(sprintf("%s/%s_%s_vcov.rds", dir, p, cp)); b <- attr(V, "coef")
  w <- numeric(length(b)); names(w) <- names(b)
  for (nm in names(ventanas)) { w[sprintf("n_%s_b%d", nm, match("[36, Inf) humedo", niv_h))] <- ventanas[nm]
                                w[sprintf("n_%s_b%d", nm, match("[36, Inf) seco", niv_h))] <- -ventanas[nm] }
  dif <- sum(w * b); se <- sqrt(drop(t(w) %*% V %*% w))
  data.table(cap = cp, dif_log = dif, se_dif = se, ratio_hum_seco = exp(dif), ratio_lo = exp(dif - 1.96 * se), ratio_hi = exp(dif + 1.96 * se),
             p = 2 * pnorm(-abs(dif / se)))
}
ch <- fread(sprintf("resultados/tablas/rezagos_expo-hum_%s.csv", p))[cantidad == acum & bin %in% c("[36, Inf) seco", "[36, Inf) humedo")]
ch <- dcast(ch[, .(cap, hum = fifelse(bin == "[36, Inf) seco", "seco", "humedo"), irr, irr_lo, irr_hi)], cap ~ hum, value.var = c("irr", "irr_lo", "irr_hi"))
i2 <- rbindlist(lapply(ch$cap, function(cp) contraste("resultados/tablas/rezagos_expo-hum", cp)))
i2[, q := p.adjust(p, "BH")]
i2 <- merge(ch, i2, by = "cap")
message(sprintf("I2: húmedo - seco con q < 0.05 en %d de %d capítulos (%d húmedo > seco, %d seco > húmedo)",
                sum(i2$q < 0.05), nrow(i2), sum(i2$q < 0.05 & i2$dif_log > 0), sum(i2$q < 0.05 & i2$dif_log < 0)))
out <- merge(i1, i2, by = "cap", all = TRUE)
fwrite(out, sprintf("resultados/tablas/humedad_comparacion_%s.csv", p))
print(out[, .(cap, dbic = round(dbic), mejor, irr_tmax = round(irr_tmax, 3), irr_at = round(irr_at, 3), irr_seco = round(irr_seco, 3),
              irr_humedo = round(irr_humedo, 3), ratio = round(ratio_hum_seco, 3), q = signif(q, 2))], nrows = 30)

# códigos (exploratorio, sin BH adicional)
dc <- "resultados/tablas/rezagos_codigos_expo-hum"
if (dir.exists(dc)) {
  cods <- sub(sprintf("^%s_([A-Z][0-9]{2})_vcov\\.rds$", p), "\\1", list.files(dc, "_vcov\\.rds$"))
  if (length(cods)) {
    cc <- rbindlist(lapply(cods, function(cp) contraste(dc, cp)))
    hc <- rbindlist(lapply(cods, function(cp) fread(sprintf("%s/%s_%s.csv", dc, p, cp))))[cantidad == acum & bin %in% c("[36, Inf) seco", "[36, Inf) humedo"), .(cap, bin, irr = round(irr, 3))]
    cat("\nCódigos, IRR >= 36 seco / húmedo y cociente:\n"); print(merge(dcast(hc, cap ~ bin, value.var = "irr"), cc[, .(cap, ratio = round(ratio_hum_seco, 3), lo = round(ratio_lo, 3), hi = round(ratio_hi, 3))], by = "cap"))
    fwrite(merge(dcast(hc, cap ~ bin, value.var = "irr"), cc, by = "cap"), sprintf("resultados/tablas/humedad_codigos_%s.csv", p))
  }
}

# --- figura 11 ---------------------------------------------------------------------
orden <- out[order(irr_tmax), cap]; out[, cap := factor(cap, levels = orden)]
a <- melt(out[, .(cap, Tmax = irr_tmax, `Temperatura aparente` = irr_at)], id.vars = "cap", value.name = "irr")
lo <- melt(out[, .(cap, Tmax = lo_tmax, `Temperatura aparente` = lo_at)], id.vars = "cap", value.name = "lo")
hi <- melt(out[, .(cap, Tmax = hi_tmax, `Temperatura aparente` = hi_at)], id.vars = "cap", value.name = "hi")
a <- merge(merge(a, lo, by = c("cap", "variable")), hi, by = c("cap", "variable"))
g1 <- ggplot(a, aes(irr, cap, colour = variable)) + geom_vline(xintercept = 1, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0, position = position_dodge(width = 0.5), linewidth = 0.3) +
  geom_point(position = position_dodge(width = 0.5), size = 1.3) +
  scale_colour_manual(values = c(Tmax = "grey25", `Temperatura aparente` = "#c44536"), name = NULL) + scale_x_log10() +
  labs(x = "IRR acumulado 0–14 d, bin ≥36 °C", y = NULL, title = "A. Tmax vs temperatura aparente (Steadman)") +
  theme_minimal(base_size = 8) + theme(legend.position = "bottom")
b <- melt(out[, .(cap, Seco = irr_seco, `Húmedo (Td ≥ 15 °C)` = irr_humedo)], id.vars = "cap", value.name = "irr")
lo <- melt(out[, .(cap, Seco = irr_lo_seco, `Húmedo (Td ≥ 15 °C)` = irr_lo_humedo)], id.vars = "cap", value.name = "lo")
hi <- melt(out[, .(cap, Seco = irr_hi_seco, `Húmedo (Td ≥ 15 °C)` = irr_hi_humedo)], id.vars = "cap", value.name = "hi")
b <- merge(merge(b, lo, by = c("cap", "variable")), hi, by = c("cap", "variable"))
b <- merge(b, out[, .(cap, sig = q < 0.05)], by = "cap")
g2 <- ggplot(b, aes(irr, cap, colour = variable)) + geom_vline(xintercept = 1, colour = "grey50") +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0, position = position_dodge(width = 0.5), linewidth = 0.3) +
  geom_point(position = position_dodge(width = 0.5), size = 1.3) +
  geom_text(data = b[sig & variable == "Seco"], aes(x = max(b$hi) * 1.05, label = "*"), colour = "black", size = 3) +
  scale_colour_manual(values = c(Seco = "#e0a030", `Húmedo (Td ≥ 15 °C)` = "#2a6f97"), name = NULL) + scale_x_log10() +
  labs(x = "IRR acumulado 0–14 d, Tmax ≥36 °C", y = NULL, title = "B. Calor seco vs húmedo",
       caption = "* diferencia húmedo − seco con q < 0.05 (BH, 16 desenlaces)") +
  theme_minimal(base_size = 8) + theme(legend.position = "bottom", axis.text.y = element_blank())
dibujar <- function() { grid.newpage(); pushViewport(viewport(layout = grid.layout(1, 2, widths = c(1.25, 1))))
  print(g1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1)); print(g2, vp = viewport(layout.pos.row = 1, layout.pos.col = 2)) }
cairo_pdf(sprintf("resultados/figuras/humedad_%s.pdf", p), width = 8.5, height = 4.6); dibujar(); dev.off()
png(sprintf("resultados/figuras/humedad_%s.png", p), width = 8.5, height = 4.6, units = "in", res = 220); dibujar(); dev.off()
message("-> humedad_comparacion_", p, ".csv, figuras/humedad_", p)
