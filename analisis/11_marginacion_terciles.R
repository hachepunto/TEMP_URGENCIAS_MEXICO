#!/usr/bin/env Rscript
# Terciles del índice de marginación municipal CONAPO 2020 (ESPECIFICACION_sensibilidad_subgrupos.md, D),
# restringidos a los 2,457 municipios del shapefile HDX 2021 (los del panel).
# Entrada: ../Datos/conapo/IMM_2020.xlsx (hoja IMM_2020), ../Datos/municipios/*.dbf
# Salida:  datos/derivados/marginacion_terciles_2020.csv (cve, IM_2020, GM_2020, tercil)
suppressMessages(library(data.table))
im <- as.data.table(readxl::read_excel("../Datos/conapo/IMM_2020.xlsx", sheet = "IMM_2020"))
im <- im[, .(cve = as.integer(CVE_MUN), IM_2020 = as.numeric(IM_2020), GM_2020, POB_TOT = as.numeric(POB_TOT))]
m  <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
x <- im[cve %in% cves]
message("municipios en CONAPO 2020: ", nrow(im), "; en el panel: ", length(cves), "; cruzan: ", nrow(x),
        "; sin índice en CONAPO: ", length(setdiff(cves, im$cve)))
stopifnot(!anyNA(x$IM_2020), !anyDuplicated(x$cve))
# terciles por número de municipios (como dice la especificación); 1 = menos marginado.
# OJO: en el método 2020 (DP2) un IM_2020 MAYOR es MENOS marginación (grado "Muy bajo" = IM alto),
# así que el tercil se define sobre -IM_2020 para que 3 = más marginado.
x[, tercil := cut(-IM_2020, quantile(-IM_2020, c(0, 1/3, 2/3, 1)), labels = 1:3, include.lowest = TRUE)]
stopifnot(x[tercil == 3, all(GM_2020 %in% c("Alto", "Muy alto", "Medio"))],
          x[tercil == 1, all(GM_2020 %in% c("Bajo", "Muy bajo"))])
print(x[, .(n = .N, IM_min = round(min(IM_2020), 2), IM_max = round(max(IM_2020), 2),
            pob_mill = round(sum(POB_TOT) / 1e6, 1)), by = tercil][order(tercil)])
print(table(x$tercil, x$GM_2020))
fwrite(x, "datos/derivados/marginacion_terciles_2020.csv")
