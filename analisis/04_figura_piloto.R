#!/usr/bin/env Rscript
# Curvas dosis-respuesta de la prueba piloto. Sólo dibuja desde la tabla; no calcula nada.
# Entrada: resultados/tablas/piloto_coeficientes.csv
# Salida:  resultados/figuras/piloto_curvas.pdf / .png

suppressMessages({library(data.table); library(ggplot2)})
dir.create("resultados/figuras", recursive = TRUE, showWarnings = FALSE)

co <- fread("resultados/tablas/piloto_coeficientes.csv")
co[, bin := factor(bin, levels = unique(bin))]
co[, modelo := factor(modelo, levels = c("dia_0", "acumulado_0_3"),
                      labels = c("Mismo día", "Acumulado 0–3 días"))]

g <- ggplot(co, aes(bin, irr, group = modelo, colour = modelo, fill = modelo)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_ribbon(aes(ymin = irr_lo, ymax = irr_hi), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.2) +
  facet_wrap(~cap, scales = "free_y") +
  scale_colour_manual(values = c("#2a6f97", "#c44536"), aesthetics = c("colour", "fill")) +
  labs(x = "Tmax diaria del municipio de residencia (°C)",
       y = "Razón de tasas vs. 24–27 °C (IC 95%)", colour = NULL, fill = NULL) +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

ggsave("resultados/figuras/piloto_curvas.pdf", g, width = 9, height = 3.8)
ggsave("resultados/figuras/piloto_curvas.png", g, width = 9, height = 3.8, dpi = 200)
message("-> resultados/figuras/piloto_curvas.{pdf,png}")
