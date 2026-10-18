#!/usr/bin/env Rscript
# Especificación H3: pruebas múltiples y contracción para el barrido por código CIE-10.
# Para cada contraste (acumulado 0-14 en [36, Inf) y en [-Inf, 12)): q-valor BH sobre beta/se
# (todos los códigos presentes, Z incluidos) y media posterior normal-normal por capítulo
# (tau^2 por DerSimonian-Laird; capítulos con < 3 códigos se contraen a la media global).
# Entrada: resultados/tablas/rezagos_codigos/2012_2025_<cie3>.csv (06 con CONTEOS=codigos),
#          datos/derivados/codigos_incluidos.csv (21)
# Salida:  resultados/tablas/codigos_fdr_2012_2025.csv (una fila por código y contraste)
suppressMessages(library(data.table))
periodo <- "2012_2025"
arch <- list.files("resultados/tablas/rezagos_codigos", sprintf("^%s_[A-Z][0-9]{2}\\.csv$", periodo), full.names = TRUE)
r <- rbindlist(lapply(arch, fread))
inc <- fread("datos/derivados/codigos_incluidos.csv")
message(length(arch), " códigos con resultados de ", nrow(inc), " comprometidos")
# los dos contrastes preespecificados (H3) son calor_36 y frio_12; los demás bins se contraen igual
# para la figura 9 pero no forman parte de la prueba comprometida
x <- r[cantidad == "acumulado_0_14" & bin != "[24,27)",
       .(cie3 = cap, bin, contraste = fcase(bin == "[36, Inf)", "calor_36", bin == "[-Inf,12)", "frio_12",
                                            default = paste0("bin_", gsub("[^0-9]", "", bin))), beta = coef, se)]
x[, preespecificado := contraste %in% c("calor_36", "frio_12")]
x <- merge(x, inc[, .(cie3, capitulo, nombre, casos)], by = "cie3")
x[, `:=`(z = beta / se, p = 2 * pnorm(-abs(beta / se)))]
x[, q := p.adjust(p, "BH"), by = contraste]

# contracción normal-normal: mu y tau^2 del grupo, media posterior por código
dl <- function(b, s) {
  w <- 1 / s^2; mu <- sum(w * b) / sum(w); k <- length(b)
  Q <- sum(w * (b - mu)^2)
  tau2 <- if (k > 1) max(0, (Q - (k - 1)) / (sum(w) - sum(w^2) / sum(w))) else 0
  list(mu = mu, tau2 = tau2)
}
x[, grupo := capitulo][, n_grupo := .N, by = .(contraste, capitulo)]
x[n_grupo < 3, grupo := "global"]
x[, c("mu", "tau2") := dl(beta, se), by = .(contraste, grupo)]
# si el grupo es "global", mu/tau2 se estiman con todos los códigos del contraste
x[grupo == "global", c("mu", "tau2") := x[contraste == .BY$contraste][, dl(beta, se)], by = contraste]
x[, beta_post := (beta / se^2 + mu / tau2) / (1 / se^2 + 1 / tau2)]
x[tau2 == 0, beta_post := mu]
x[, `:=`(irr = exp(beta), irr_lo = exp(beta - 1.96 * se), irr_hi = exp(beta + 1.96 * se), irr_post = exp(beta_post),
         sig = q < 0.05)]
x[, orden := -abs(beta_post)]; setorder(x, contraste, orden)
out <- x[, .(contraste, bin, preespecificado, cie3, capitulo, nombre, casos, beta, se, z, p, q, sig, grupo, mu, tau2, beta_post, irr, irr_lo, irr_hi, irr_post)]
fwrite(out, sprintf("resultados/tablas/codigos_fdr_%s.csv", periodo))
for (ct in c("calor_36", "frio_12")) {
  y <- out[contraste == ct]
  message(sprintf("\n%s: %d/%d con q < 0.05 (%d suben, %d bajan); controles Z: %d/%d con q < 0.05",
                  ct, sum(y$sig), nrow(y), sum(y$sig & y$beta > 0), sum(y$sig & y$beta < 0),
                  sum(y$sig & y$capitulo == "Z_control"), sum(y$capitulo == "Z_control")))
  print(y[1:min(15, nrow(y)), .(cie3, capitulo, nombre = substr(nombre, 1, 40), irr = round(irr, 3), irr_post = round(irr_post, 3), q = signif(q, 2))])
}
message("-> resultados/tablas/codigos_fdr_", periodo, ".csv")
