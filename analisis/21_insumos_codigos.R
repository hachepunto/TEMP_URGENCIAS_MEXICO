#!/usr/bin/env Rscript
# Conteos diarios por municipio de residencia y código CIE-10 de 3 caracteres para el barrido
# exploratorio de la especificación H (ESPECIFICACION_codigos.md): códigos con >= 100,000
# atenciones con residencia válida en 2012-2025 (sin 2013). La lista se fija aquí y no cambia.
# Entrada: datos/derivados/urgencias_2012_2025.parquet (01)
# Salida:  datos/derivados/conteos_codigos_2012_2025.parquet (cve, fecha, cap = cie3, casos; sin ceros)
#          datos/derivados/codigos_incluidos.csv (cie3, capitulo, casos, mun_dias)
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
umbral <- 100000L
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
d <- as.data.table(read_parquet("datos/derivados/urgencias_2012_2025.parquet", col_select = c("fecha", "ent_res", "mun_res", "cie3")))
d <- d[!is.na(mun_res) & ent_res %in% 1:32][, cve := ent_res * 1000L + mun_res][cve %in% cves]
d[, cie3 := toupper(substr(cie3, 1, 3))]
n <- d[, .(casos = .N, mun_dias = uniqueN(cve * 100000L + as.integer(fecha))), by = cie3][casos >= umbral][order(cie3)]
n[, capitulo := fcase(cie3 >= "A00" & cie3 <= "B99", "infecciosas", cie3 >= "C00" & cie3 <= "D48", "tumores",
                      cie3 >= "D50" & cie3 <= "D89", "sangre", cie3 >= "E00" & cie3 <= "E90", "endocrinas",
                      cie3 >= "F00" & cie3 <= "F99", "mentales", cie3 >= "G00" & cie3 <= "G99", "nervioso",
                      cie3 >= "H00" & cie3 <= "H59", "ojo", cie3 >= "H60" & cie3 <= "H95", "oido",
                      cie3 >= "I00" & cie3 <= "I99", "circulatorio", cie3 >= "J00" & cie3 <= "J99", "respiratorio",
                      cie3 >= "K00" & cie3 <= "K93", "digestivo", cie3 >= "L00" & cie3 <= "L99", "piel",
                      cie3 >= "M00" & cie3 <= "M99", "osteomuscular", cie3 >= "N00" & cie3 <= "N99", "genitourinario",
                      cie3 >= "O00" & cie3 <= "O99", "embarazo", cie3 >= "P00" & cie3 <= "P96", "perinatal",
                      cie3 >= "Q00" & cie3 <= "Q99", "congenitas", cie3 >= "R00" & cie3 <= "R99", "sintomas",
                      cie3 >= "S00" & cie3 <= "T98", "traumatismos", cie3 >= "U00" & cie3 <= "U99", "covid",
                      cie3 >= "V01" & cie3 <= "Y98", "externas", cie3 >= "Z00" & cie3 <= "Z99", "Z_control",
                      default = "otro")]
stopifnot(!any(n$capitulo == "otro"))
message(sprintf("codigos con >= %d atenciones: %d (%.1f%% de las atenciones con residencia valida)",
                umbral, nrow(n), 100 * sum(n$casos) / nrow(d)))
print(n[, .(codigos = .N, casos = sum(casos)), by = capitulo][order(-casos)])
# nombre del código (catálogo DGIS; la copia del repo Datos/cie10/ está vacía, se usa la de PROYECTO_URGENCIAS)
cat10 <- fread("/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/CODIGOS_CIE10/codigos_cie_10_capitulo_mexico.csv", encoding = "UTF-8")
setnames(cat10, sub("^﻿", "", names(cat10)))
cat10[, c3 := sub("X$", "", CLAVE)]   # los códigos sin subdivisión vienen como "I10X", "E86X"
n[cat10[nchar(c3) == 3], nombre := i.NOMBRE, on = .(cie3 = c3)]
message("codigos sin nombre en el catalogo: ", sum(is.na(n$nombre)))
fwrite(n[, .(cie3, capitulo, nombre, casos, mun_dias)], "datos/derivados/codigos_incluidos.csv")
conteos <- d[cie3 %in% n$cie3, .(casos = .N), by = .(cve, fecha, cap = cie3)]
write_parquet(conteos, "datos/derivados/conteos_codigos_2012_2025.parquet")
message("-> conteos_codigos_2012_2025.parquet (", format(nrow(conteos), big.mark = ","), " filas) y codigos_incluidos.csv")
