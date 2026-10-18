#!/usr/bin/env Rscript
# Figura 9 (especificación H7): heatmap código CIE-10 × bin de Tmax del log-IRR contraído
# (acumulado 0-14 d), ordenado por capítulo; punto en las celdas de los dos contrastes
# preespecificados con q < 0.05. Sólo lee resultados/tablas/codigos_fdr_2012_2025.csv (22).
suppressMessages({library(data.table); library(ggplot2)})
x <- fread("resultados/tablas/codigos_fdr_2012_2025.csv")
niveles <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)", "[27,30)", "[30,33)", "[33,36)", "[36, Inf)")
etq <- c("<12", "12-15", "15-18", "18-21", "21-24", "24-27", "27-30", "30-33", "33-36", "≥36")
x[, bin := factor(bin, levels = niveles, labels = etq)]
# orden: capítulo (como en las figuras de capítulos), dentro del capítulo por efecto de calor contraído
orden_cap <- c("infecciosas", "sangre", "endocrinas", "mentales", "nervioso", "ojo", "oido", "circulatorio",
               "respiratorio", "digestivo", "piel", "osteomuscular", "genitourinario", "sintomas", "traumatismos",
               "embarazo", "perinatal", "tumores", "covid", "Z_control")
calor <- x[contraste == "calor_36", .(cie3, capitulo, b_calor = beta_post)]
calor[, capitulo := factor(capitulo, levels = orden_cap)]
setorder(calor, capitulo, -b_calor)
x[, cie3 := factor(cie3, levels = rev(calor$cie3))]
x[, capitulo := factor(capitulo, levels = orden_cap, labels = sub("Z_control", "Z (control)", orden_cap))]
x[, etiqueta := sprintf("%s %s", cie3, tolower(substr(nombre, 1, 38)))]
etiquetas <- unique(x[, .(cie3, etiqueta)]); setkey(etiquetas, cie3)
lim <- 0.5   # log-IRR; ±0.5 ≈ IRR 0.61–1.65; T63 y E86 se saturan y se anotan
x[, b_plot := pmax(pmin(beta_post, lim), -lim)]
g <- ggplot(x, aes(bin, cie3, fill = b_plot)) + geom_tile(colour = "white", linewidth = 0.2) +
  geom_point(data = x[preespecificado & sig & abs(beta_post) <= lim], size = 0.9, colour = "black") +
  geom_point(data = x[preespecificado & sig & abs(beta_post) > lim], size = 0.9, colour = "black", position = position_nudge(x = 0.33)) +
  geom_text(data = x[abs(beta_post) > lim], aes(label = sprintf("%.2f", exp(beta_post))), size = 1.8, colour = "white", nudge_x = -0.08) +
  scale_fill_gradient2(low = "#2a6f97", mid = "grey97", high = "#c44536", midpoint = 0, limits = c(-lim, lim),
                       name = "log-IRR acumulado 0–14 d\n(contraído, ref. 24–27 °C)") +
  scale_y_discrete(labels = function(v) etiquetas[v, etiqueta]) +
  facet_grid(capitulo ~ ., scales = "free_y", space = "free_y", switch = "y") +
  labs(x = "Tmax del día (°C)", y = NULL,
       caption = "Punto: q < 0.05 (BH) en los contrastes preespecificados (<12 y ≥36 °C). Celdas con |log-IRR| > 0.5 muestran el IRR.") +
  theme_minimal(base_size = 7) +
  theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1, size = 6),
        panel.spacing.y = unit(1, "pt"), axis.text.y = element_text(size = 4.6), legend.position = "top",
        legend.key.height = unit(3, "pt"), legend.key.width = unit(20, "pt"), panel.grid = element_blank())
n <- uniqueN(x$cie3); h <- 1.5 + n * 0.075
cairo_pdf("resultados/figuras/codigos_heatmap_2012_2025.pdf", width = 6.5, height = h); print(g); dev.off()
png("resultados/figuras/codigos_heatmap_2012_2025.png", width = 6.5, height = h, units = "in", res = 220); print(g); dev.off()
message("-> resultados/figuras/codigos_heatmap_2012_2025 (", n, " códigos)")
