#!/usr/bin/env Rscript
# Marginación a clima de base constante (ESPECIFICACION_sensibilidad_subgrupos.md, E).
# Junta los CSV por celda clima × marginación, calcula M3 vs M1 dentro de cada estrato climático
# (EE por suma de varianzas) y dibuja. Sólo lee las tablas de 06 y celdas_clima_marg.csv.
# Uso: Rscript 14_figura_clima_marg.R <periodo>
# Salida: resultados/tablas/clima_marg_<periodo>.csv, resultados/figuras/clima_marg_<periodo>.{pdf,png}

suppressMessages({library(data.table); library(ggplot2)})
periodo <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(!is.na(periodo))
celdas <- fread("resultados/tablas/celdas_clima_marg.csv")
r <- rbindlist(lapply(1:3, function(cc) rbindlist(lapply(1:3, function(k) {
  dir <- sprintf("resultados/tablas/rezagos_clima%d_marg%d", cc, k)
  arch <- list.files(dir, sprintf("^%s_", periodo), full.names = TRUE); arch <- arch[!grepl("_resumen", arch)]
  rbindlist(lapply(arch, fread))[, `:=`(clima = cc, marg = k)]
}))))
x <- r[cantidad == "acumulado_0_14" & bin %in% c("[33,36)", "[36, Inf)")]
x <- merge(x, celdas[, .(clima, marg, ge36_identificado)], by = c("clima", "marg"))
x[bin == "[36, Inf)" & !ge36_identificado, `:=`(irr = NA_real_, irr_lo = NA_real_, irr_hi = NA_real_, coef = NA_real_, se = NA_real_)]
# contraste M3 vs M1 dentro de cada clima y bin
d <- dcast(x[marg %in% c(1, 3)], cap + clima + bin ~ marg, value.var = c("coef", "se"))
d[, `:=`(dif = coef_3 - coef_1, se_dif = sqrt(se_3^2 + se_1^2))]
d[, `:=`(ratio_3vs1 = exp(dif), ratio_lo = exp(dif - 1.96 * se_dif), ratio_hi = exp(dif + 1.96 * se_dif), z = dif / se_dif)]
out <- merge(x[, .(cap, clima, marg, bin, irr, irr_lo, irr_hi)],
             d[, .(cap, clima, bin, ratio_3vs1, ratio_lo, ratio_hi, z)], by = c("cap", "clima", "bin"), all.x = TRUE)
setorder(out, cap, bin, clima, marg)
fwrite(out, sprintf("resultados/tablas/clima_marg_%s.csv", periodo))
cat("M3 vs M1 por estrato climático (acumulado 0-14):\n")
print(d[!is.na(ratio_3vs1), .(cap, clima, bin, ratio = round(ratio_3vs1, 3), lo = round(ratio_lo, 3), hi = round(ratio_hi, 3), z = round(z, 2))][order(bin, cap, clima)])

x[, clima_lab := factor(clima, 1:3, c("C1 templado", "C2", "C3 cálido"))]
x[, marg_lab := factor(marg, 1:3, c("M1 menos marginado", "M2", "M3 más marginado"))]
g <- ggplot(x[!is.na(irr)], aes(clima_lab, irr, colour = marg_lab)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey40") +
  geom_pointrange(aes(ymin = irr_lo, ymax = irr_hi), position = position_dodge(width = 0.5), size = 0.25) +
  facet_grid(bin ~ cap, scales = "free_y") +
  scale_colour_manual(values = c("#2a6f97", "#7a7a7a", "#c44536")) +
  labs(x = "Estrato de clima de base", y = "Razón de tasas acumulada 0–14 vs 24–27 °C", colour = NULL) +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom", axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(sprintf("resultados/figuras/clima_marg_%s.pdf", periodo), g, width = 11, height = 5.5, device = cairo_pdf)
ggsave(sprintf("resultados/figuras/clima_marg_%s.png", periodo), g, width = 11, height = 5.5, dpi = 200)
message("-> resultados/{tablas,figuras}/clima_marg_", periodo)
