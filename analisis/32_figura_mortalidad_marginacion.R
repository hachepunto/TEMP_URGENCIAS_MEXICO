#!/usr/bin/env Rscript
# Figura del gradiente de mortalidad por calor según marginación: cocientes M3/M1 (o T3/T1) del acumulado
# 0-14 a Tmax >= 36 °C en G (ii)-(iii), J y K, para todas las causas y circulatorio. Sólo dibuja desde las tablas.
# Entrada: resultados/tablas/defunciones_marginacion_2012_2025.csv (28), defunciones_clima_marg_2012_2025.csv (28),
#          mortalidad_edad_calidad_2012_2025.csv (29), mortalidad_gradiente_k_2012_2025.csv (31)
# Salida:  resultados/figuras/mortalidad_marginacion_2012_2025.{pdf,png}
suppressMessages({library(data.table); library(ggplot2)})
T <- "resultados/tablas"
g  <- fread(file.path(T, "defunciones_marginacion_2012_2025.csv"))[fuente == "defunciones" & cap %in% c("todas", "circulatorio")]
g  <- g[, .(grupo = "G: marginación", fila = "Todos los municipios", causa = cap, ratio, lo, hi)]
cl <- fread(file.path(T, "defunciones_clima_marg_2012_2025.csv"))[clima == 3 & bin == "[36, Inf)" & cap %in% c("todas", "circulatorio")]
cl <- cl[, .(grupo = "G: marginación", fila = "Clima de base cálido (C3)", causa = cap, ratio, lo, hi)]
j  <- fread(file.path(T, "mortalidad_edad_calidad_2012_2025.csv"))[parte != "G (ii) referencia, todos los municipios"]
j[, causa := sub("_.*", "", cap)]
j[, fila := fcase(grepl("65mas", cap), "Edad ≥ 65", grepl("menos65", cap), "Edad < 65", default = "Municipios con buen registro")]
j <- j[, .(grupo = "J: edad y registro", fila, causa, ratio, lo, hi)]
k  <- fread(file.path(T, "mortalidad_gradiente_k_2012_2025.csv"))[parte != "G (ii) referencia"]
k[, causa := fifelse(grepl("circulatorio", cap), "circulatorio", "todas")]
nom_ind <- c(PL5000 = "Ruralidad (loc. < 5 mil)", VHAC = "Hacinamiento", OVPT = "Piso de tierra", OVSEE = "Sin electricidad", PO2SM = "Ingreso ≤ 2 SM")
k[, fila := fcase(grepl("urbano", cap), "Residencia urbana", grepl("rural", cap), "Residencia rural",
                  grepl("conasist", cap), "Con asistencia médica", grepl("sinasist", cap), "Sin asistencia médica",
                  default = paste0(nom_ind[sub(":.*", "", cap)], " (T3/T1)"))]
k[, grupo := fcase(parte == "K-a ámbito", "K: ámbito", parte == "K-c asistencia", "K: asistencia", default = "K: componentes IMM")]
x <- rbind(g, cl, j, k[, .(grupo, fila, causa, ratio, lo, hi)])
stopifnot(!anyNA(x))
x[, grupo := factor(grupo, unique(grupo))]
x[, fila := factor(fila, rev(unique(fila)))]
stopifnot(!anyDuplicated(x[, .(grupo, fila, causa)]))
x[, causa := factor(causa, c("todas", "circulatorio"), c("Todas las causas", "Circulatorio"))]
p <- ggplot(x, aes(ratio, fila)) +
  geom_vline(xintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(xmin = lo, xmax = hi, colour = hi < 1), size = 0.25) +
  facet_grid(grupo ~ causa, scales = "free_y", space = "free_y", switch = "y") +
  scale_x_log10() + scale_colour_manual(values = c(`FALSE` = "#7a7a7a", `TRUE` = "#c44536"), guide = "none") +
  labs(x = "Cociente más / menos marginado (M3/M1 o T3/T1) de la razón de tasas acumulada 0–14\nTmax ≥ 36 °C vs 24–27 °C; en rojo, IC 95 % por debajo de 1", y = NULL) +
  theme_minimal(base_size = 9) + theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1),
                                       panel.spacing.y = unit(0.6, "lines"))
dir.create("resultados/figuras", showWarnings = FALSE)
ggsave("resultados/figuras/mortalidad_marginacion_2012_2025.pdf", p, width = 9, height = 6.5, device = cairo_pdf)
ggsave("resultados/figuras/mortalidad_marginacion_2012_2025.png", p, width = 9, height = 6.5, dpi = 200)
message("-> resultados/figuras/mortalidad_marginacion_2012_2025.{pdf,png}")
