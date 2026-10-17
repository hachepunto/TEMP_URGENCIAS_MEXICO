#!/usr/bin/env Rscript
# Residencia vs municipio del hospital (ESPECIFICACION F). Forest pareado + tabla. Sólo lee tablas.
# Uso: Rscript 16_figura_hospital.R <periodo>
suppressMessages({library(data.table); library(ggplot2)})
periodo <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(!is.na(periodo))
r <- rbind(fread(sprintf("resultados/tablas/rezagos_%s.csv", periodo))[, asig := "Municipio de residencia"],
           fread(sprintf("resultados/tablas/rezagos_hospital_%s.csv", periodo))[, asig := "Municipio del hospital"])
x <- r[bin == "[36, Inf)" & cantidad %in% c("v0", "acumulado_0_14")]
x[, cantidad := factor(cantidad, c("v0", "acumulado_0_14"), c("Mismo día", "Acumulado 0–14 días"))]
orden <- x[asig == "Municipio de residencia" & cantidad == "Acumulado 0–14 días"][order(irr), cap]
x[, cap := factor(cap, levels = orden)]
tab <- dcast(x, cap + cantidad ~ asig, value.var = c("irr", "irr_lo", "irr_hi"))
fwrite(tab, sprintf("resultados/tablas/residencia_vs_hospital_irr_%s.csv", periodo))
g <- ggplot(x, aes(irr, cap, colour = asig)) +
  geom_vline(xintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(xmin = irr_lo, xmax = irr_hi), position = position_dodge(width = 0.6), size = 0.25) +
  facet_wrap(~cantidad) + scale_colour_manual(values = c("#c44536", "#2a6f97")) +
  labs(x = "Razón de tasas, Tmax ≥ 36 °C vs 24–27 °C (IC 95%)", y = NULL, colour = "Asignación de la exposición") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(sprintf("resultados/figuras/residencia_vs_hospital_%s.pdf", periodo), g, width = 8.5, height = 5.5, device = cairo_pdf)
ggsave(sprintf("resultados/figuras/residencia_vs_hospital_%s.png", periodo), g, width = 8.5, height = 5.5, dpi = 200)
print(dcast(x[cantidad == "Acumulado 0–14 días"], cap ~ asig, value.var = "irr")[, dif := round(`Municipio del hospital` - `Municipio de residencia`, 3)][])
