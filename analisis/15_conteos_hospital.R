#!/usr/bin/env Rscript
# Conteos diarios por MUNICIPIO DE LA UNIDAD (CLUES), 15 capítulos + total
# (ESPECIFICACION_sensibilidad_subgrupos.md, F). Mismos rangos CIE-10 que 05.
# Entrada: datos/derivados/urgencias_2012_2025.parquet, /STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/CATALOGO_CLUES/CATCLUES_2023_actualizado.csv (la copia del repo está vacía)
# Salida:  datos/derivados/conteos_hospital_2012_2025.parquet; resultados/tablas/residencia_vs_hospital.csv
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
anios <- 2012:2025
cat <- fread("/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/CATALOGO_CLUES/CATCLUES_2023_actualizado.csv", encoding = "UTF-8")
setnames(cat, names(cat), gsub("^﻿", "", names(cat)))
cat <- cat[, .(clues = trimws(CLUES), cve_hosp = as.integer(`CLAVE DE LA ENTIDAD`) * 1000L + as.integer(`CLAVE DEL MUNICIPIO`))]
stopifnot(!anyDuplicated(cat$clues))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
capitulos <- data.table(
  cap = c("infecciosas", "sangre", "endocrinas", "mentales", "nervioso", "ojo", "oido", "circulatorio",
          "respiratorio", "digestivo", "piel", "osteomuscular", "genitourinario", "sintomas", "traumatismos"),
  desde = c("A00", "D50", "E00", "F00", "G00", "H00", "H60", "I00", "J00", "K00", "L00", "M00", "N00", "R00", "S00"),
  hasta = c("B99", "D89", "E90", "F99", "G99", "H59", "H95", "I99", "J99", "K93", "L99", "M99", "N99", "R99", "T98"))
llave <- function(x) match(substr(x, 1, 1), LETTERS) * 100L + suppressWarnings(as.integer(substr(x, 2, 3)))
capitulos[, `:=`(k1 = llave(desde), k2 = llave(hasta))]

u <- as.data.table(read_parquet("datos/derivados/urgencias_2012_2025.parquet",
                                col_select = c("fecha", "ent_res", "mun_res", "clues", "cie3")))
u <- u[fecha >= as.IDate(sprintf("%d-01-01", min(anios))) & fecha <= as.IDate(sprintf("%d-12-31", max(anios)))]
n0 <- nrow(u)
u[cat, cve_hosp := i.cve_hosp, on = "clues"]
message(sprintf("CLUES sin catálogo: %.2f%% de atenciones; municipio del hospital sin polígono: %.2f%%",
                100 * mean(is.na(u$cve_hosp)), 100 * mean(!is.na(u$cve_hosp) & !u$cve_hosp %in% cves)))
u <- u[cve_hosp %in% cves]
cods <- data.table(cie3 = unique(u$cie3))[, k := llave(cie3)]
cods[capitulos, cap := i.cap, on = .(k >= k1, k <= k2)]
u[cods, cap := i.cap, on = "cie3"]
# descriptivo: residencia vs municipio del hospital (sólo atenciones con residencia válida)
r <- u[ent_res %in% 1:32 & !is.na(mun_res)]
r[, cve_res := ent_res * 1000L + mun_res]
marg <- fread("datos/derivados/marginacion_terciles_2020.csv")[, .(cve_res = cve, tercil)]
r[marg, tercil := i.tercil, on = "cve_res"]
desc <- rbind(r[, .(grupo = "total", n = .N, pct_otro_municipio = round(100 * mean(cve_res != cve_hosp), 2))],
              r[!is.na(tercil), .(n = .N, pct_otro_municipio = round(100 * mean(cve_res != cve_hosp), 2)), by = .(grupo = paste0("marg", tercil))][order(grupo)])
print(desc); fwrite(desc, "resultados/tablas/residencia_vs_hospital.csv")
conteos <- u[!is.na(cap), .(casos = .N), by = .(cve = cve_hosp, fecha, cap)]
conteos <- rbind(conteos, conteos[, .(cap = "total", casos = sum(casos)), by = .(cve, fecha)], use.names = TRUE)
write_parquet(conteos, sprintf("datos/derivados/conteos_hospital_%d_%d.parquet", min(anios), max(anios)))
message("-> conteos_hospital: ", format(nrow(conteos), big.mark = ","), " filas; municipios con unidad: ", uniqueN(conteos$cve))
