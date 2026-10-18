#!/usr/bin/env Rscript
# Especificación J-a: conteos diarios de defunciones por municipio de residencia en dos grupos de edad
# (< 65 y >= 65 años), para todas las causas y circulatorio (I00-I99). Edad no especificada: fuera.
# Entrada: datos/derivados/defunciones_2012_2024.parquet (19)
# Salida:  datos/derivados/conteos_defunciones_edad_2012_2025.parquet (cve, fecha, cap, casos; sin ceros)
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
d <- as.data.table(read_parquet("datos/derivados/defunciones_2012_2024.parquet", col_select = c("fecha", "ent_res", "mun_res", "cie3", "edad_anios")))
d <- d[ent_res %in% 1:32 & !is.na(mun_res)][, cve := ent_res * 1000L + mun_res][cve %in% cves]
message(sprintf("edad no especificada: %.2f%% (fuera de estos desenlaces)", 100 * mean(is.na(d$edad_anios))))
d <- d[!is.na(edad_anios)][, grupo := fifelse(edad_anios >= 65L, "65mas", "menos65")]
d[, circ := substr(cie3, 1, 1) == "I"]
conteos <- rbind(d[, .(casos = .N), by = .(cve, fecha, cap = paste0("todas_", grupo))],
                 d[circ == TRUE, .(casos = .N), by = .(cve, fecha, cap = paste0("circulatorio_", grupo))])
print(conteos[, .(casos = sum(casos)), by = cap])
write_parquet(conteos, "datos/derivados/conteos_defunciones_edad_2012_2025.parquet")
message("-> conteos_defunciones_edad_2012_2025.parquet")

# J-b: municipios de registro de buena calidad (regla comprometida): >= 100 defunciones y en o por debajo
# del percentil 75 nacional (entre esos municipios) en % fecha incompleta Y en % registro tardío
q <- fread("datos/derivados/calidad_defunciones_municipio.csv")[cve %in% cves & defunciones >= 100]
p75_f <- quantile(q$pct_fecha_incompleta, 0.75); p75_t <- quantile(q$pct_registro_tardio, 0.75)
buenos <- q[pct_fecha_incompleta <= p75_f & pct_registro_tardio <= p75_t, cve]
message(sprintf("J-b: %d municipios con >= 100 defunciones; p75 fecha incompleta %.3f%%, p75 registro tardío %.2f%%; buena calidad: %d",
                nrow(q), p75_f, p75_t, length(buenos)))
writeLines(as.character(sort(buenos)), "datos/derivados/municipios_registro_bueno.txt")
