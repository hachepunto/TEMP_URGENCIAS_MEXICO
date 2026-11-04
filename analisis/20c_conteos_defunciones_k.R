#!/usr/bin/env Rscript
# Especificación K (ESPECIFICACION_mortalidad_gradiente_K.md): insumos para explicar el gradiente inverso de
# mortalidad por calor según marginación.
# K-a/K-c: conteos diarios por municipio de residencia de todas (A00-Z99) y circulatorio (I00-I99), mismas
#   llaves que 20, partidos por ámbito de la localidad de residencia (area_ur 1 urbana, 2 rural) y por
#   asistencia médica (asist_medi 1 con, 2 sin); otros valores quedan fuera sólo de esos desenlaces.
# K-b: terciles (por número de municipios del panel) de 5 indicadores del IMM 2020; T3 = mayor carencia.
# Entrada: datos/derivados/defunciones_2012_2024.parquet (19), ../Datos/conapo/IMM_2020.xlsx
# Salida:  datos/derivados/conteos_defunciones_k_2012_2025.parquet (cve, fecha, cap, casos; sin ceros)
#          datos/derivados/comp_<indicador>_t<k>.txt (cve por tercil) y componentes_imm_terciles_2020.csv
suppressMessages({library(data.table); library(arrow)}); setDTthreads(as.integer(Sys.getenv("NHILOS", "8")))
m <- as.data.table(foreign::read.dbf("../Datos/municipios/mex_admbnda_adm2_govmex_20210618.dbf", as.is = TRUE))
cves <- as.integer(sub("^MX", "", m$ADM2_PCODE))
d <- as.data.table(read_parquet("datos/derivados/defunciones_2012_2024.parquet", col_select = c("fecha", "ent_res", "mun_res", "cie3", "asist_medi", "area_ur")))
d <- d[ent_res %in% 1:32 & !is.na(mun_res)][, cve := ent_res * 1000L + mun_res][cve %in% cves]
llave <- function(x) match(substr(x, 1, 1), LETTERS) * 100L + suppressWarnings(as.integer(substr(x, 2, 3)))
d[, k := llave(cie3)]
d <- d[k >= llave("A00") & k <= llave("Z99")]
d[, circ := k >= llave("I00") & k <= llave("I99")]
d[, ambito := fcase(area_ur == 1L, "urbano", area_ur == 2L, "rural", default = NA_character_)]
d[, asist := fcase(asist_medi == 1L, "conasist", asist_medi == 2L, "sinasist", default = NA_character_)]
message(sprintf("todas: %s; area_ur no especificado %.2f%%; asist_medi no especificado %.2f%%",
                format(nrow(d), big.mark = ","), 100 * mean(is.na(d$ambito)), 100 * mean(is.na(d$asist))))
partir <- function(v) rbind(d[!is.na(get(v)), .(casos = .N), by = .(cve, fecha, cap = paste0("todas_", get(v)))],
                            d[!is.na(get(v)) & circ == TRUE, .(casos = .N), by = .(cve, fecha, cap = paste0("circulatorio_", get(v)))])
conteos <- rbind(partir("ambito"), partir("asist"))
print(conteos[, .(casos = sum(casos)), by = cap])
stopifnot(uniqueN(conteos$cap) == 8)
write_parquet(conteos, "datos/derivados/conteos_defunciones_k_2012_2025.parquet")
message("-> conteos_defunciones_k_2012_2025.parquet")

# K-b: terciles de componentes del IMM. Empates (p. ej. muchos municipios en 0 % sin electricidad) se
# rompen por rango determinista (valor y luego cve) para que los terciles tengan el mismo número de municipios.
im <- as.data.table(readxl::read_excel("../Datos/conapo/IMM_2020.xlsx", sheet = "IMM_2020"))
ind <- c("PL.5000", "VHAC", "OVPT", "OVSEE", "PO2SM")
stopifnot(all(ind %in% names(im)))
im <- im[, c(list(cve = as.integer(CVE_MUN), IM_2020 = as.numeric(IM_2020)), lapply(.SD, as.numeric)), .SDcols = ind][cve %in% cves]
stopifnot(nrow(im) == length(cves), !anyNA(im))
for (v in ind) {
  if (v == "PL.5000") {
    # enmienda a K-b antes de correr: 1,265 de 2,457 municipios tienen 100 %; T3 = totalmente rurales y
    # T1/T2 = mitades del resto (el desempate por cve habría partido el empate por estado)
    resto <- im[[v]] < 100; o <- order(im[[v]][resto], im$cve[resto]); r <- integer(sum(resto)); r[o] <- seq_len(sum(resto))
    tt <- rep(3L, nrow(im)); tt[resto] <- as.integer(ceiling(2 * r / sum(resto)))
    set(im, j = paste0("t_", v), value = tt)
  } else {
    o <- order(im[[v]], im$cve); r <- integer(nrow(im)); r[o] <- seq_len(nrow(im))
    set(im, j = paste0("t_", v), value = as.integer(ceiling(3 * r / nrow(im))))
  }
  for (t in 1:3) writeLines(as.character(sort(im[get(paste0("t_", v)) == t, cve])), sprintf("datos/derivados/comp_%s_t%d.txt", sub("\\.", "", v), t))
  message(sprintf("%s: municipios por tercil %s; corte T1/T2 %.2f, T2/T3 %.2f; empates en el valor mínimo: %d municipios", v, paste(tabulate(im[[paste0("t_", v)]], 3), collapse = "/"),
                  max(im[get(paste0("t_", v)) == 1, get(v)]), max(im[get(paste0("t_", v)) == 2, get(v)]), sum(im[[v]] == min(im[[v]]))))
}
fwrite(im, "datos/derivados/componentes_imm_terciles_2020.csv")
