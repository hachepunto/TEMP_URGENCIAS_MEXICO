#!/usr/bin/env Rscript
# Conteos diarios por municipio de residencia para subgrupos clínicos de 3 caracteres
# (ESPECIFICACION_sensibilidad_subgrupos.md, sección B): E86, N17, I21.
# Entrada: datos/derivados/urgencias_2012_2025.parquet
# Salida:  datos/derivados/conteos_subgrupos_2012_2025.parquet (cve, fecha, cap, casos; sin ceros)
suppressMessages({library(data.table); library(arrow)})
setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025
sub   <- c(E86 = "deshidratacion", N17 = "renal_aguda", I21 = "infarto")
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
u <- as.data.table(read_parquet("datos/derivados/urgencias_2012_2025.parquet",
                                col_select = c("fecha", "ent_res", "mun_res", "cie3")))
u <- u[cie3 %in% names(sub) & ent_res %in% 1:32 & !is.na(mun_res) & mun_res < 999 &
         fecha >= as.IDate(sprintf("%d-01-01", min(anios))) & fecha <= as.IDate(sprintf("%d-12-31", max(anios)))]
u[, cve := ent_res * 1000L + mun_res]; u <- u[cve %in% cves]
u[, cap := paste0(cie3, "_", sub[cie3])]
print(u[, .N, by = cap])
conteos <- u[, .(casos = .N), by = .(cve, fecha, cap)]
write_parquet(conteos, sprintf("datos/derivados/conteos_subgrupos_%d_%d.parquet", min(anios), max(anios)))
message("-> conteos_subgrupos: ", nrow(conteos), " filas")
