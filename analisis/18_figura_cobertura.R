#!/usr/bin/env Rscript
# Figura S2: cobertura por institución 2012-2025 (área apilada) y volumen anual por estado relativo a 2019.
# Sólo lee resultados/tablas/cobertura_*.csv (salida de 09).
suppressMessages({library(data.table); library(ggplot2); library(grid)})
a <- fread("resultados/tablas/cobertura_institucion_anio.csv")
a[, inst2 := ifelse(inst %in% c("SSA", "IMB"), inst, "otras")]
a <- a[, .(N = sum(N)), by = .(anio, inst2)]
g1 <- ggplot(a, aes(anio, N / 1e6, fill = inst2)) + geom_area(alpha = 0.85) +
  scale_fill_manual(values = c(IMB = "#c44536", SSA = "#2a6f97", otras = "grey70"), name = "Institución (CLUES)") +
  labs(x = NULL, y = "Atenciones por año (millones)") + theme_minimal(base_size = 10) + theme(legend.position = "bottom")
e <- fread("resultados/tablas/cobertura_estado_anio.csv")
g2 <- ggplot(e[anio >= 2014], aes(anio, idx_2019, group = ent_clues)) +
  geom_line(alpha = 0.4, colour = "#2a6f97") +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") + coord_cartesian(ylim = c(0.3, 2)) +
  labs(x = NULL, y = "Volumen anual relativo a 2019 (una línea por estado)") + theme_minimal(base_size = 10)
dibujar <- function() {
  grid.newpage(); pushViewport(viewport(layout = grid.layout(1, 2)))
  print(g1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(g2, vp = viewport(layout.pos.row = 1, layout.pos.col = 2))
}
cairo_pdf("resultados/figuras/cobertura_2012_2025.pdf", width = 10, height = 3.8); dibujar(); dev.off()
png("resultados/figuras/cobertura_2012_2025.png", width = 10, height = 3.8, units = "in", res = 200); dibujar(); dev.off()
message("-> resultados/figuras/cobertura_2012_2025")
