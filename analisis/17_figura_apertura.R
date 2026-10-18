#!/usr/bin/env Rscript
# Figura de apertura: la señal en los datos crudos a escala nacional, verano 2023.
# Panel: atenciones diarias por deshidratación (E86) de residentes de los 7 estados con más días >= 36 °C
# (SR, NL, VZ, YN, TS, OC, CL) y, el mismo día, el número de esos municipios con Tmax >= 36 °C.
suppressMessages({library(data.table); library(arrow); library(ggplot2)})
d0 <- as.IDate("2023-05-01"); d1 <- as.IDate("2023-09-30"); ents <- c(26L, 19L, 30L, 31L, 28L, 20L, 5L)
co <- as.data.table(read_parquet("datos/derivados/conteos_subgrupos_2012_2025.parquet"))[cap == "E86_deshidratacion" & fecha >= d0 & fecha <= d1 & (cve %/% 1000L) %in% ents]
cl <- as.data.table(read_parquet("datos/derivados/clima_ventanas_2012_2025.parquet", col_select = c("cve", "fecha", "bin")))[fecha >= d0 & fecha <= d1 & (cve %/% 1000L) %in% ents]
x <- merge(cl[, .(mun_ge36 = sum(bin == 10)), by = fecha], co[, .(casos = sum(casos)), by = fecha], by = "fecha", all.x = TRUE)[is.na(casos), casos := 0L]
x[, casos_m7 := frollmean(casos, 7, align = "center")]
esc <- max(x$casos) / max(x$mun_ge36)
g <- ggplot(x, aes(fecha)) +
  geom_col(aes(y = casos), fill = "#2a6f97", alpha = 0.45, width = 1) +
  geom_line(aes(y = casos_m7), colour = "#2a6f97", linewidth = 0.8) +
  geom_line(aes(y = mun_ge36 * esc), colour = "#c44536", linewidth = 0.7) +
  scale_y_continuous("Urgencias por deshidratación (E86) por día", sec.axis = sec_axis(~ . / esc, name = "Municipios con Tmax ≥ 36 °C")) +
  labs(x = NULL, caption = "Residentes de SON, NL, VER, YUC, TAM, OAX y COAH, may–sep 2023. Azul: casos diarios y media móvil de 7 días. Rojo: municipios de esos estados con Tmax ≥ 36 °C.") +
  theme_minimal(base_size = 10) + theme(axis.title.y.right = element_text(colour = "#c44536"), plot.caption = element_text(size = 7))
ggsave("resultados/figuras/apertura_e86_2023.pdf", g, width = 9, height = 3.6, device = cairo_pdf)
ggsave("resultados/figuras/apertura_e86_2023.png", g, width = 9, height = 3.6, dpi = 200)
cat(sprintf("cor(casos, mun_ge36) = %.2f; casos/día cuando mun_ge36 >= p75: %.0f vs <= p25: %.0f\n", cor(x$casos, x$mun_ge36),
            x[mun_ge36 >= quantile(mun_ge36, .75), mean(casos)], x[mun_ge36 <= quantile(mun_ge36, .25), mean(casos)]))
