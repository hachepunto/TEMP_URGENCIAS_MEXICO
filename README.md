# Temperatura y urgencias en México

¿Cómo cambia el número diario de atenciones de urgencias con la temperatura, por capítulo
CIE-10? Panel municipio de residencia × día, 2012–2025, con datos de urgencias de la DGIS
(Secretaría de Salud) y temperatura diaria de Daymet v4 promediada por municipio.

Proyecto iniciado por Diana Álvarez ([dialvas/TEMP_URGENCIAS_MEXICO](https://github.com/dialvas/TEMP_URGENCIAS_MEXICO),
2023–2024) y retomado en 2026. Su código original se conserva sin cambios en `legacy/`.

## Estado

**Prueba piloto (2026-10-16)**, tres capítulos, especificación fijada antes de ver resultados
(ver bitácora del proyecto). Razón de tasas en días con Tmax ≥ 36 °C frente a 24–27 °C,
2012–2025 (119 M atenciones):

| Capítulo | Mismo día | Acumulado 0–3 días |
|---|---|---|
| Traumatismos y envenenamientos (S, T) | 1.138 [1.128, 1.147] | 1.169 [1.156, 1.181] |
| Genitourinario (N) | 1.085 [1.075, 1.095] | 1.112 [1.096, 1.128] |
| Circulatorio (I) | 0.964 [0.953, 0.975] | 0.927 [0.911, 0.943] |

Fuente: `analisis/resultados/tablas/piloto_coeficientes_2012_2025.csv`; figura en
`analisis/resultados/figuras/piloto_curvas_2012_2025.png`. Con 2012–2022 (`*_2012_2022.*`) las
estimaciones son prácticamente iguales. No es un resultado final: falta sensibilidad a la
especificación de efectos fijos, festivos y rezagos más largos, y el resto de los capítulos.

**Todos los capítulos con rezagos 0–14 (2026-10-16)**, especificación en
`analisis/ESPECIFICACION_capitulos_rezagos.md` (comprometida antes de correr). Efecto acumulado
0–14 días de un día con Tmax ≥ 36 °C frente a 24–27 °C, 2012–2025:

| Capítulo | Mismo día | Acumulado 0–14 |
|---|---|---|
| Infecciosas | 1.120 [1.107, 1.134] | 1.170 [1.134, 1.206] |
| Endocrinas | 1.134 [1.118, 1.150] | 1.159 [1.124, 1.194] |
| Sangre | 1.069 [1.041, 1.097] | 1.151 [1.078, 1.229] |
| Genitourinario | 1.070 [1.061, 1.080] | 1.146 [1.116, 1.177] |
| Piel | 1.062 [1.046, 1.078] | 1.133 [1.093, 1.175] |
| Traumatismos | 1.118 [1.108, 1.127] | 1.132 [1.110, 1.156] |
| Síntomas | 1.072 [1.063, 1.081] | 1.108 [1.081, 1.136] |
| Ojo | 1.039 [1.011, 1.068] | 1.100 [1.031, 1.173] |
| Mentales | 1.099 [1.081, 1.118] | 1.083 [1.048, 1.119] |
| Oído | 1.020 [1.003, 1.038] | 1.047 [0.989, 1.108] |
| Total (15 capítulos) | 1.067 [1.061, 1.072] | 1.037 [1.018, 1.056] |
| Osteomuscular | 1.033 [1.020, 1.046] | 1.032 [0.996, 1.069] |
| Digestivo | 1.011 [1.003, 1.019] | 1.027 [1.003, 1.051] |
| Nervioso | 1.041 [1.022, 1.061] | 0.950 [0.912, 0.989] |
| Circulatorio | 0.979 [0.967, 0.992] | 0.900 [0.872, 0.928] |
| Respiratorio | 1.026 [1.017, 1.035] | 0.775 [0.746, 0.805] |

Fuente: `analisis/resultados/tablas/rezagos_2012_2025.csv`; figuras
`analisis/resultados/figuras/rezagos_{forest,curvas,perfil}_2012_2025.png`.

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
  07_figuras_rezagos.R    forest, curvas y perfil por ventana
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
```

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
- 2015 y 2018 contienen líneas corruptas; se descartan (71 y 20 líneas) y se registran en el log.
- 2020–2021: COVID-19 y transición Seguro Popular → INSABI; desde 2023, transferencia de unidades
  a IMSS-Bienestar (claves CLUES `…IMB…`).
