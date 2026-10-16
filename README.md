# Temperatura y urgencias en México

¿Cómo cambia el número diario de atenciones de urgencias con la temperatura, por capítulo
CIE-10? Panel municipio de residencia × día, 2012–2022, con datos de urgencias de la DGIS
(Secretaría de Salud) y temperatura diaria de Daymet v4 promediada por municipio.

Proyecto iniciado por Diana Álvarez ([dialvas/TEMP_URGENCIAS_MEXICO](https://github.com/dialvas/TEMP_URGENCIAS_MEXICO),
2023–2024) y retomado en 2026. Su código original se conserva sin cambios en `legacy/`.

## Estado

**Prueba piloto (2026-10-16)**, tres capítulos, especificación fijada antes de ver resultados
(ver bitácora del proyecto). Razón de tasas en días con Tmax ≥ 36 °C frente a 24–27 °C:

| Capítulo | Mismo día | Acumulado 0–3 días |
|---|---|---|
| Traumatismos y envenenamientos (S, T) | 1.137 [1.126, 1.148] | 1.170 [1.155, 1.185] |
| Genitourinario (N) | 1.081 [1.068, 1.093] | 1.112 [1.093, 1.132] |
| Circulatorio (I) | 0.957 [0.944, 0.970] | 0.919 [0.900, 0.938] |

Fuente: `analisis/resultados/tablas/piloto_coeficientes.csv`; figura en
`analisis/resultados/figuras/piloto_curvas.png`. No es un resultado final: falta 2023,
sensibilidad a la especificación de efectos fijos, festivos y rezagos más largos.

## Estructura

```
analisis/                 pipeline actual
  01_leer_urgencias.R     bases crudas DGIS 2012-2022 -> tabla compacta (parquet)
  02_panel.R              panel municipio × día × capítulo con ceros + clima diario
  03_modelo_piloto.R      Poisson con efectos fijos (fixest), Tmax en bins de 3 °C
  04_figura_piloto.R      curvas dosis-respuesta (sólo dibuja desde la tabla)
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

En fx-ld1 (INMEGEN), con el env conda `bio` (R 4.5, `data.table`, `arrow`, `fixest`):

```bash
cd analisis
for s in 01_leer_urgencias 02_panel 03_modelo_piloto 04_figura_piloto; do
  LC_ALL=C.UTF-8 Rscript $s.R > logs/$s.log 2>&1
done
```

Entradas fuera de git (rutas en el encabezado de cada script):
- Urgencias DGIS 2012–2022: `/STORAGE/genut/dalvarez/PROYECTO_URGENCIAS/DATOS/DATOS_URGENCIAS/`
  ([fuente](http://www.dgis.salud.gob.mx/contenidos/basesdedatos/da_urgencias_gobmx.html)).
- Clima diario por municipio: `/STORAGE/genut/dalvarez/TEMPERATURA_MEXICO_MUNICIPAL/day_results/`,
  derivado de Daymet v4 ([ORNL DAAC](https://daac.ornl.gov/cgi-bin/dataset_lister.pl?p=32)).
- Polígonos municipales: `Datos/municipios/` ([HDX](https://data.humdata.org/dataset/cod-ab-mex)).

## Cautelas

- Las bases DGIS cubren sobre todo unidades de la Secretaría de Salud, no IMSS/ISSSTE.
- 2015 y 2018 contienen líneas corruptas; se descartan (71 y 20 líneas) y se registran en el log.
- 2020–2021: COVID-19 y transición Seguro Popular → INSABI.
