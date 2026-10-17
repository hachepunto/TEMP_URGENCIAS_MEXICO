#!/usr/bin/env Rscript
# Figuras del modelo de todos los capítulos con rezagos. Sólo dibuja desde la tabla.
# Uso: Rscript 07_figuras_rezagos.R <periodo>
# Entrada: resultados/tablas/rezagos_<periodo>.csv
# Salida:  resultados/figuras/rezagos_{forest,curvas,perfil}_<periodo>.{pdf,png}

suppressMessages({library(data.table); library(ggplot2)})
periodo <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(!is.na(periodo))
dir.create("resultados/figuras", recursive = TRUE, showWarnings = FALSE)
guardar <- function(g, nombre, w, h) {
  ggsave(sprintf("resultados/figuras/%s_%s.pdf", nombre, periodo), g, width = w, height = h, device = cairo_pdf)
  ggsave(sprintf("resultados/figuras/%s_%s.png", nombre, periodo), g, width = w, height = h, dpi = 200)
}
niveles <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)",
             "[27,30)", "[30,33)", "[33,36)", "[36, Inf)")
r <- fread(sprintf("resultados/tablas/rezagos_%s.csv", periodo))
r[, bin := factor(bin, levels = niveles)]
tema <- theme_minimal(base_size = 10)

# 1. forest: Tmax >= 36 vs 24-27, mismo día y acumulado 0-14
f <- r[bin == "[36, Inf)" & cantidad %in% c("v0", "acumulado_0_14")]
orden <- f[cantidad == "acumulado_0_14"][order(irr), cap]
f[, cap := factor(cap, levels = orden)]
f[, cantidad := factor(cantidad, c("v0", "acumulado_0_14"), c("Mismo día", "Acumulado 0–14 días"))]
g1 <- ggplot(f, aes(irr, cap, colour = cantidad)) +
  geom_vline(xintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(xmin = irr_lo, xmax = irr_hi), position = position_dodge(width = 0.6), size = 0.25) +
  scale_colour_manual(values = c("#2a6f97", "#c44536")) +
  labs(x = "Razón de tasas, Tmax ≥ 36 °C vs 24–27 °C (IC 95%)", y = NULL, colour = NULL) +
  tema + theme(legend.position = "bottom")
guardar(g1, "rezagos_forest", 6.5, 5.5)

# 2. curvas del acumulado 0-14 por capítulo
c2 <- r[cantidad == "acumulado_0_14"]
c2[, cap := factor(cap, levels = orden)]
g2 <- ggplot(c2, aes(bin, irr, group = 1)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_ribbon(aes(ymin = irr_lo, ymax = irr_hi), fill = "#c44536", alpha = 0.15) +
  geom_line(colour = "#c44536", linewidth = 0.6) + geom_point(colour = "#c44536", size = 0.8) +
  facet_wrap(~cap, scales = "free_y", ncol = 4) +
  labs(x = "Tmax diaria del municipio de residencia (°C)",
       y = "Razón de tasas acumulada 0–14 días vs 24–27 °C") +
  tema + theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 6))
guardar(g2, "rezagos_curvas", 10, 9)

# 3. perfil por ventana (efecto por día de rezago), Tmax >= 36
p <- r[bin == "[36, Inf)" & cantidad %in% c("v0", "v1_3", "v4_7", "v8_14")]
p[, cantidad := factor(cantidad, c("v0", "v1_3", "v4_7", "v8_14"), c("0", "1–3", "4–7", "8–14"))]
p[, cap := factor(cap, levels = orden)]
g3 <- ggplot(p, aes(cantidad, irr)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(ymin = irr_lo, ymax = irr_hi), colour = "#2a6f97", size = 0.2) +
  facet_wrap(~cap, scales = "free_y", ncol = 4) +
  labs(x = "Ventana de rezago (días)", y = "Razón de tasas por día de rezago, Tmax ≥ 36 °C") +
  tema
guardar(g3, "rezagos_perfil", 9, 8)
message("-> resultados/figuras/rezagos_{forest,curvas,perfil}_", periodo)
