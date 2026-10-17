#!/usr/bin/env Rscript
# Figuras de sensibilidad y subgrupos. Sólo dibuja desde las tablas.
# Uso: Rscript 10_figuras_sensibilidad.R <periodo>
# Entrada: resultados/tablas/rezagos_<periodo>.csv, rezagos_fe-anio_semana_<periodo>.csv,
#          rezagos_subgrupos_<periodo>.csv
# Salida:  resultados/figuras/sensibilidad_fe_<periodo>.{pdf,png}, subgrupos_<periodo>.{pdf,png}

suppressMessages({library(data.table); library(ggplot2)})
periodo <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(!is.na(periodo))
guardar <- function(g, nombre, w, h) {
  ggsave(sprintf("resultados/figuras/%s_%s.pdf", nombre, periodo), g, width = w, height = h, device = cairo_pdf)
  ggsave(sprintf("resultados/figuras/%s_%s.png", nombre, periodo), g, width = w, height = h, dpi = 200)
}
tema <- theme_minimal(base_size = 10) + theme(legend.position = "bottom")
leer <- function(suf, etiqueta) fread(sprintf("resultados/tablas/rezagos%s_%s.csv", suf, periodo))[, fe := etiqueta]

# 1. principal vs sensibilidad A, acumulado 0-14, extremos de calor y frío
r <- rbind(leer("", "mun×año×mes + edo×dow (principal)"),
           leer("_fe-anio_semana", "mun×año + edo×semana + edo×dow (sensibilidad A)"))
f <- r[cantidad == "acumulado_0_14" & bin %in% c("[36, Inf)", "[-Inf,12)")]
f[, bin := factor(bin, c("[36, Inf)", "[-Inf,12)"), c("Tmax ≥ 36 °C", "Tmax < 12 °C"))]
orden <- f[fe == unique(fe)[1] & bin == "Tmax ≥ 36 °C"][order(irr), cap]
f[, cap := factor(cap, levels = orden)]
g1 <- ggplot(f, aes(irr, cap, colour = fe)) +
  geom_vline(xintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(xmin = irr_lo, xmax = irr_hi), position = position_dodge(width = 0.6), size = 0.25) +
  facet_wrap(~bin, scales = "free_x") +
  scale_colour_manual(values = c("#c44536", "#2a6f97")) +
  labs(x = "Razón de tasas acumulada 0–14 días vs 24–27 °C (IC 95%)", y = NULL, colour = NULL) +
  tema + guides(colour = guide_legend(nrow = 2))
guardar(g1, "sensibilidad_fe", 8, 6)

# 2. subgrupos clínicos: curva acumulada 0-14 y perfil por ventana
s <- fread(sprintf("resultados/tablas/rezagos_subgrupos_%s.csv", periodo))
niveles <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)",
             "[27,30)", "[30,33)", "[33,36)", "[36, Inf)")
s[, bin := factor(bin, levels = niveles)]
s2 <- s[cantidad == "acumulado_0_14"]
g2 <- ggplot(s2, aes(bin, irr, group = 1)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_ribbon(aes(ymin = irr_lo, ymax = irr_hi), fill = "#c44536", alpha = 0.15) +
  geom_line(colour = "#c44536", linewidth = 0.6) + geom_point(colour = "#c44536", size = 0.9) +
  facet_wrap(~cap, scales = "free_y") +
  labs(x = "Tmax diaria del municipio de residencia (°C)",
       y = "Razón de tasas acumulada 0–14 días vs 24–27 °C") +
  tema + theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 7))
guardar(g2, "subgrupos", 9, 3.6)
message("-> resultados/figuras/{sensibilidad_fe,subgrupos}_", periodo)
