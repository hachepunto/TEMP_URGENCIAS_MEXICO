# Temperatura y urgencias en México

¿Cómo cambia el número diario de atenciones de urgencias con la temperatura, por capítulo
CIE-10? Panel municipio de residencia × día, 2012–2025, con datos de urgencias de la DGIS
(Secretaría de Salud) y temperatura diaria de Daymet v4 promediada por municipio.

Proyecto iniciado por Diana Álvarez ([dialvas/TEMP_URGENCIAS_MEXICO](https://github.com/dialvas/TEMP_URGENCIAS_MEXICO),
2023–2024) y retomado en 2026. Su código original se conserva sin cambios en `legacy/`.

## Estado

**2026-10-17.** Resultados vigentes = corridas **sin 2013** (el archivo DGIS 2013 no identifica el
municipio de residencia; ver `analisis/AUDITORIA_2026-10-17.md`). Los resultados previos con 2013
están congelados en `analisis/resultados/historico/2026-10-17_con2013/`; las diferencias son del
segundo o tercer decimal. Borrador del manuscrito en `Drive:Claude-remote/temp-urgencias/manuscript/`.

Efecto acumulado 0–14 días de un día con Tmax ≥ 36 °C frente a 24–27 °C, 2012–2025 sin 2013,
exposición por municipio de residencia (`analisis/resultados/tablas/rezagos_2012_2025.csv`):

| Capítulo | Mismo día | Acumulado 0–14 |
|---|---|---|
| Infecciosas | 1.126 | 1.182 [1.146, 1.219] |
| Endocrinas | 1.133 | 1.156 [1.120, 1.193] |
| Genitourinario | 1.070 | 1.142 [1.111, 1.174] |
| Sangre | 1.066 | 1.138 [1.064, 1.217] |
| Piel | 1.063 | 1.133 [1.094, 1.173] |
| Traumatismos | 1.113 | 1.124 [1.102, 1.146] |
| Síntomas | 1.071 | 1.106 [1.078, 1.134] |
| Ojo | 1.039 | 1.096 [1.026, 1.170] |
| Mentales | 1.099 | 1.086 [1.052, 1.122] |
| Oído | 1.023 | 1.063 [1.007, 1.121] |
| Total (15 capítulos) | 1.067 | 1.038 [1.020, 1.056] |
| Digestivo | 1.011 | 1.026 [1.002, 1.051] |
| Osteomuscular | 1.031 | 1.023 [0.986, 1.061] |
| Nervioso | 1.041 | 0.955 [0.917, 0.995] |
| Circulatorio | 0.979 | 0.897 [0.868, 0.928] |
| Respiratorio | 1.028 | 0.783 [0.756, 0.811] |

Subgrupos: deshidratación E86 2.11 [1.91, 2.33]; renal aguda N17 0.94 [0.74, 1.19] (adelanto);
infarto I21 0.99 [0.84, 1.16]. Exposición por municipio del hospital: diferencias < 0.03 salvo
sangre y mentales. Sensibilidad de efectos fijos (mun×año + edo×semana): efectos del calor a la
mitad y frío < 12 °C con efecto negativo en todos los capítulos (fragilidad reportada). Sin gradiente
por marginación, tampoco a clima de base constante.

Antecedentes directos: Sarmiento, Colelli & Pavanello (RFF WP 25-11, 2025) y Aguilar-Gomez, Graff
Zivin & Neidell (NBER 33491, 2025), ambos con exposición por municipio del hospital; ver
`analisis/LITERATURA_2026-10-17.md`.

## Estructura

```
analisis/                 pipeline actual
  00_clima_municipal.R    Daymet NetCDF -> Tmax/precip diaria por municipio (terra)
  01_leer_urgencias.R     bases crudas DGIS 2012-2025 -> tabla compacta (parquet)
  02_panel.R              panel municipio × día × capítulo con ceros + clima diario
  03_modelo_piloto.R      Poisson con efectos fijos (fixest), Tmax en bins de 3 °C
  04_figura_piloto.R      curvas dosis-respuesta (sólo dibuja desde la tabla)
  05_insumos_capitulos.R  conteos de 15 capítulos + total; clima con conteos de días por ventana de rezago
  06_modelo_rezagos.R     Poisson FE por capítulo, rezagos 0, 1-3, 4-7, 8-14; acumulado 0-14
  06b_juntar_rezagos.R    junta los CSV por desenlace de una variante de 06
  07_figuras_rezagos.R    forest, curvas y perfil por ventana
  08_insumos_subgrupos.R  conteos E86 / N17 / I21
  09_cobertura_clues.R    atenciones por institución (SSA, IMB) y estado-año
  10_figuras_sensibilidad.R  principal vs sensibilidad A; subgrupos
  11_marginacion_terciles.R  terciles CONAPO 2020 (IM alto = menos marginación)
  12_figura_marginacion.R / 13_clima_base.R / 14_figura_clima_marg.R  heterogeneidad D y E
  15_conteos_hospital.R   conteos por municipio de la CLUES (especificación F); 16_figura_hospital.R
  17_figura_apertura.R    ola de calor de junio 2023: E86 vs municipios >= 36 °C
  ESPECIFICACION_*.md     especificaciones comprometidas antes de correr (fechadas en git)
  AUDITORIA_2026-10-17.md / LITERATURA_2026-10-17.md  informes de agentes independientes
  logs/                   log de cada corrida
  resultados/             tablas (csv) y figuras
legacy/                   código y salidas originales de Diana (no se usan; ver abajo)
Datos/                    catálogos pequeños e instrucciones de descarga
```

## Modelo

```
casos ~ i(bin_tmax, ref = [24,27)) + i(bin_prcp) | municipio^año^mes + estado^día_semana
```

- Poisson con efectos fijos (`fixest::fepois`), errores agrupados por municipio.
- Unidad: municipio de **residencia** del paciente (`ENTRESIDENCIA` + `MUNRESIDENCIA`), por eso
  arranca en 2012; antes no existe `MUNRESIDENCIA`.
- **Ceros explícitos**: todos los municipio-días, haya o no atenciones.
- Los efectos fijos municipio × año × mes absorben población, estacionalidad local y cambios
  en el reporte de unidades; la identificación sale de la variación diaria dentro del mes.
- Exposición: Tmax y precipitación diarias de Daymet v4, promedio sobre el polígono municipal
  (HDX 2021, 2,457 municipios).

## Por qué no se usa el análisis original

Los scripts de `legacy/scripts_diana/` agregaban con `group_by() |> n()`, así que los días sin
atenciones desaparecían del panel; asignaban la temperatura al municipio del hospital (CLUES) y
no al de residencia, y usaban efectos fijos de día del mes en lugar de día de la semana.

## Reproducir

En fx-ld1 (INMEGEN), con el env conda `bio` (R 4.5, `data.table`, `arrow`, `fixest`, `terra`).
`NHILOS` fija los hilos (8 por defecto); 03 y 04 reciben el periodo.

```bash
cd analisis
export LC_ALL=C.UTF-8 NHILOS=8
Rscript 01_leer_urgencias.R && Rscript 02_panel.R
Rscript 03_modelo_piloto.R 2012_2025 && Rscript 04_figura_piloto.R 2012_2025
Rscript 05_insumos_capitulos.R && Rscript 06_modelo_rezagos.R 2012_2025 && Rscript 07_figuras_rezagos.R 2012_2025
# variantes de 06: FE_SPEC=anio_semana | CONTEOS=subgrupos|hospital | MARG=1..3 | CLIMA=1..3 (ver encabezado)
```
Paquetes además de los de arriba: `ggplot2`, `foreign`, `readxl`. No editar un script mientras una
corrida suya está en curso (R lo lee expresión por expresión).

Clima 2023-2025 (Daymet V4R1, requiere cuenta NASA Earthdata):
`GDAL_DRIVER_PATH=<env>/lib/gdalplugins PROJ_DATA=<env>/share/proj Rscript 00_clima_municipal.R <archivo.nc> <dir_salida>`

Entradas fuera de git (rutas en el encabezado de cada script):
- Urgencias DGIS 2012–2025: `/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DATOS_URGENCIAS/`
  ([fuente](http://www.dgis.salud.gob.mx/contenidos/basesdedatos/da_urgencias_gobmx.html)).
- Clima diario por municipio: `/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL/day_results/`
  (2008–2022, Daymet V4.0) y `day_results_v4r1/` (2023–2025, Daymet V4R1, `00_clima_municipal.R`).
  En 2022 ambas versiones coinciden (cor = 1, dif. máx. 0.026 °C).
  Fuente: [ORNL DAAC](https://daac.ornl.gov/cgi-bin/dsviewer.pl?ds_id=2129).
- Polígonos municipales: `Datos/municipios/` ([HDX](https://data.humdata.org/dataset/cod-ab-mex)).

## Cautelas

- Las bases DGIS cubren sobre todo unidades de la Secretaría de Salud, no IMSS/ISSSTE.
- 2013 excluido (municipio de residencia inválido en la fuente). 2012: 26 % sin municipio de
  residencia, concentrado en Colima, Quintana Roo, Tamaulipas e Hidalgo.
- 2015 y 2018 contienen líneas corruptas; se descartan (72 y 20 líneas) y se registran en el log.
- 2020–2021: COVID-19 y transición Seguro Popular → INSABI; en 2024 el 67 % de las atenciones pasa a
  clave IMSS-Bienestar (mismas unidades reetiquetadas; volumen por estado sin salto atribuible).
- El bin ≥ 36 °C se identifica sobre todo en 7 estados del norte y el Golfo; 588 municipios nunca lo
  alcanzan.
