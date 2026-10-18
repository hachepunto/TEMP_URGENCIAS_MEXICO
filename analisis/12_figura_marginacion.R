#!/usr/bin/env Rscript
# Heterogeneidad por terciles de marginación (ESPECIFICACION_sensibilidad_subgrupos.md, D).
# Junta los CSV por tercil, calcula la diferencia alto - bajo (en log-IRR, EE por suma de
# varianzas: estratos independientes) y dibuja. Sólo lee las tablas de 06.
# Uso: Rscript 12_figura_marginacion.R <periodo>
# Salida: resultados/tablas/marginacion_<periodo>.csv, resultados/figuras/marginacion_<periodo>.{pdf,png}

suppressMessages({library(data.table); library(ggplot2)})
periodo <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(!is.na(periodo))
r <- rbindlist(lapply(1:3, function(k) {
  arch <- list.files(sprintf("resultados/tablas/rezagos_marg%d", k), sprintf("^%s_.*[^n]\\.csv$", periodo), full.names = TRUE)
  arch <- arch[!grepl("_resumen", arch)]
  rbindlist(lapply(arch, fread))[, tercil := k]
}))
x <- r[cantidad == "acumulado_0_14" & bin == "[36, Inf)"]
x[, tercil_lab := factor(tercil, 1:3, c("1 (menos marginado)", "2", "3 (más marginado)"))]
# diferencia tercil 3 - tercil 1 en log-IRR
d <- dcast(x, cap ~ tercil, value.var = c("coef", "se"))
d[, `:=`(dif = coef_3 - coef_1, se_dif = sqrt(se_3^2 + se_1^2))]
d[, `:=`(ratio = exp(dif), ratio_lo = exp(dif - 1.96 * se_dif), ratio_hi = exp(dif + 1.96 * se_dif),
         z = dif / se_dif)]
out <- merge(x[, .(cap, tercil, irr, irr_lo, irr_hi)], d[, .(cap, ratio_3vs1 = ratio, ratio_lo, ratio_hi, z)], by = "cap")
fwrite(out, sprintf("resultados/tablas/marginacion_%s.csv", periodo))
print(d[, .(cap, ratio = round(ratio, 3), lo = round(ratio_lo, 3), hi = round(ratio_hi, 3), z = round(z, 2))])

g <- ggplot(x, aes(tercil_lab, irr, colour = tercil_lab)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(ymin = irr_lo, ymax = irr_hi), size = 0.3) +
  facet_wrap(~cap, nrow = 1, scales = "free_y") +
  scale_colour_manual(values = c("#2a6f97", "#7a7a7a", "#c44536")) +
  labs(x = "Tercil de marginación CONAPO 2020", y = "Razón de tasas acumulada 0–14, Tmax ≥ 36 °C vs 24–27 °C",
       colour = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", axis.text.x = element_blank())
ggsave(sprintf("resultados/figuras/marginacion_%s.pdf", periodo), g, width = 10, height = 3.6, device = cairo_pdf)
ggsave(sprintf("resultados/figuras/marginacion_%s.png", periodo), g, width = 10, height = 3.6, dpi = 200)
message("-> resultados/{tablas,figuras}/marginacion_", periodo)
