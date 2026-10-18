#!/usr/bin/env Rscript
# Figura 8 (especificación G, contraste i): curva dosis-respuesta del acumulado 0-14 d por bin de Tmax,
# urgencias vs mortalidad, para total/todas, circulatorio y respiratorio. Sólo lee tablas de 06.
# Entrada: resultados/tablas/rezagos_2012_2025.csv, rezagos_defunciones_2012_2025.csv
# Salida:  resultados/tablas/urgencias_vs_mortalidad_2012_2025.csv, resultados/figuras/urgencias_mortalidad_2012_2025.{pdf,png}
suppressMessages({library(data.table); library(ggplot2)})
p <- "2012_2025"
niveles <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)", "[27,30)", "[30,33)", "[33,36)", "[36, Inf)")
etq <- c("<12", "12-15", "15-18", "18-21", "21-24", "24-27", "27-30", "30-33", "33-36", "≥36")
u <- fread(sprintf("resultados/tablas/rezagos_%s.csv", p))[cantidad == "acumulado_0_14" & cap %in% c("total", "circulatorio", "respiratorio")]
d <- fread(sprintf("resultados/tablas/rezagos_defunciones_%s.csv", p))[cantidad == "acumulado_0_14" & cap %in% c("todas", "circulatorio", "respiratorio")]
u[, fuente := "Urgencias (DGIS)"]; d[, fuente := "Defunciones (INEGI/DGIS)"]
d[cap == "todas", cap := "total"]
x <- rbind(u, d)[, .(fuente, cap, bin, irr, irr_lo, irr_hi)]
x[, bin := factor(bin, levels = niveles, labels = etq)]
x[, cap := factor(cap, levels = c("total", "circulatorio", "respiratorio"), labels = c("Total / todas las causas", "Circulatorio (I)", "Respiratorio (J)"))]
fwrite(x, sprintf("resultados/tablas/urgencias_vs_mortalidad_%s.csv", p))
g <- ggplot(x, aes(bin, irr, colour = fuente, group = fuente)) +
  geom_hline(yintercept = 1, colour = "grey50") +
  geom_ribbon(aes(ymin = irr_lo, ymax = irr_hi, fill = fuente), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.6) + geom_point(size = 1.2) +
  facet_wrap(~ cap, nrow = 1) + scale_y_log10() + coord_cartesian(ylim = c(0.6, 1.6)) +
  scale_colour_manual(values = c(`Urgencias (DGIS)` = "#2a6f97", `Defunciones (INEGI/DGIS)` = "#c44536"), name = NULL) +
  scale_fill_manual(values = c(`Urgencias (DGIS)` = "#2a6f97", `Defunciones (INEGI/DGIS)` = "#c44536"), name = NULL) +
  labs(x = "Tmax del día (°C)", y = "IRR acumulado 0–14 d (ref. 24–27 °C)",
       caption = "Mismos municipios de residencia, mismo clima y mismo modelo. Urgencias 2012–2025 sin 2012-12-26..2013-12-25; defunciones 2012–2024 por fecha de ocurrencia.") +
  theme_minimal(base_size = 8) + theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1), plot.caption = element_text(hjust = 0))
cairo_pdf(sprintf("resultados/figuras/urgencias_mortalidad_%s.pdf", p), width = 8, height = 3.4); print(g); dev.off()
png(sprintf("resultados/figuras/urgencias_mortalidad_%s.png", p), width = 8, height = 3.4, units = "in", res = 220); print(g); dev.off()
message("-> urgencias_vs_mortalidad_", p, ".csv, figuras/urgencias_mortalidad_", p)
