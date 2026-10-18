#!/usr/bin/env Rscript
# Junta los CSV por desenlace de 06 en una tabla por variante (misma salida que el paso final de 06).
# Uso: Rscript 06b_juntar_rezagos.R <periodo> [sufijo]   (sufijo: "", "_fe-anio_semana", "_hospital", "_marg1", ...)
suppressMessages(library(data.table))
args <- commandArgs(trailingOnly = TRUE); periodo <- args[1]; sufijo <- if (length(args) > 1) args[2] else ""
dir_in <- paste0("resultados/tablas/rezagos", sufijo)
arch <- list.files(dir_in, sprintf("^%s_.*\\.csv$", periodo), full.names = TRUE)
res  <- arch[grepl("_resumen\\.csv$", arch)]; arch <- setdiff(arch, res)
niveles <- c("[-Inf,12)", "[12,15)", "[15,18)", "[18,21)", "[21,24)", "[24,27)", "[27,30)", "[30,33)", "[33,36)", "[33,36) seco", "[33,36) humedo", "[36, Inf)", "[36, Inf) seco", "[36, Inf) humedo")   # incluye los de EXPO=hum
r <- rbindlist(lapply(arch, fread)); r[, bin := factor(bin, levels = niveles)]; setorder(r, cap, cantidad, bin)
fwrite(r, sprintf("resultados/tablas/rezagos%s_%s.csv", sufijo, periodo))
fwrite(rbindlist(lapply(res, fread)), sprintf("resultados/tablas/rezagos%s_%s_resumen.csv", sufijo, periodo))
message("-> rezagos", sufijo, "_", periodo, ".csv: ", uniqueN(r$cap), " desenlaces")
