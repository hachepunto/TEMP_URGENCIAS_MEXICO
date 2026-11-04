# Especificación comprometida L-a: ¿la aclimatación explica el gradiente inverso de mortalidad por calor? Umbrales relativos a la distribución local de Tmax

Escrita el 2026-11-04, **antes de construir la exposición relativa y de correr nada de esta etapa**. Motivación: el exceso de mortalidad a Tmax ≥ 36 °C es menor en el tercil más marginado (G ii: todas M3/M1 0.921 [0.869, 0.977]; circulatorio 0.838) y no lo explican la edad, la calidad del registro (J), el ámbito urbano/rural, los componentes del IMM ni la asistencia médica (K). Queda la aclimatación: un mismo umbral absoluto es un día más o menos extremo según el clima habitual del municipio. G (iii) ya dio un indicio en contra (en el estrato de clima cálido el cociente es 0.87), pero los terciles de clima de base son gruesos; esto lo prueba municipio por municipio.

## Exposición

Para cada municipio, percentiles de su Tmax diaria (Daymet, promedio del polígono, la misma serie de `05`) sobre **todos los días de 2011–2025** (el periodo de clima que ya usa el pipeline, incluido el año de rezagos). Diez bins por percentil local, con los mismos cortes en todos los municipios:

`[0,1)`, `[1,5)`, `[5,10)`, `[10,25)`, **`[25,75)` (referencia)**, `[75,90)`, `[90,95)`, `[95,97.5)`, `[97.5,99)`, `[99,100]`.

Misma construcción de ventanas que `05`/`25` (0, 1–3, 4–7, 8–14; conteo de días por bin), misma precipitación en bins y mismo panel. `06` la usa con `EXPO=rel`.

## Modelo y contrastes

El de G (Poisson FE `cve^anio^mes + ent^dow`, EE por municipio, 2012–2024). Contraste principal: **acumulado 0–14 en el bin `[99,100]` frente a `[25,75)`**. Desenlaces: todas, circulatorio y todas ≥ 65 (el estrato donde J ubicó el gradiente). Nacional y por tercil de marginación (`MARG=1,2,3`); cociente M3/M1 con EE por suma de varianzas; BH sobre los 3 cocientes.

## Criterio fijado aquí

La aclimatación **explica** el gradiente si, en todas las causas a `[99,100]`, el cociente M3/M1 tiene IC 95 % que incluye 1 y su estimación puntual está más cerca de 1 que 0.921. **No lo explica** si el cociente sigue < 1 con IC que excluye 1 y ancho del IC del log-cociente < 0.4. Cualquier otro patrón es **indeterminado**. Si el cociente sale > 1 con IC que excluye 1 (M3 más afectado por un día localmente extremo), se reporta como **inversión**: el gradiente absoluto sería atribuible a la aclimatación y, en escala relativa, la marginación sí aumentaría la vulnerabilidad.

Secundario (no entra en el criterio): mismo cociente en `[97.5,99)` y en circulatorio y ≥ 65; curva completa de IRR por percentil para M1 y M3.

Límites declarados: (i) el contraste `[99,100]` vs `[25,75)` no tiene la misma magnitud que `≥ 36` vs `24–27`, así que comparar el cociente con 0.921 es una regla de decisión, no una equivalencia; (ii) el percentil local mezcla aclimatación fisiológica, conductual y de infraestructura y no las separa; (iii) en municipios fríos `[99,100]` puede caer por debajo de 30 °C, así que ahora identifican el efecto todos los municipios, no sólo los 7 estados donde se concentra ≥ 36 °C.

## Implementación

- `33_clima_relativo.R` → `datos/derivados/clima_ventanas_rel_2012_2025.parquet` y `tmax_percentiles_municipio.csv` (cortes por municipio).
- `06_modelo_rezagos.R`: `EXPO=rel` (10 niveles por percentil, referencia `[25,75)`).
- `34_mortalidad_aclimatacion.R`: cocientes y criterio → `mortalidad_aclimatacion_2012_2025.csv`; `32` añade el grupo L a la figura 12.
