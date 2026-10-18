# Especificación comprometida I: humedad y temperatura aparente

Escrita el 2026-10-17, **antes de correr ningún modelo de esta etapa**. Sensibilidad del modelo
principal (`ESPECIFICACION_capitulos_rezagos.md`) a la humedad. Insumo nuevo: presión de vapor
diaria Daymet V4R1 (`vp`, Pa) 2011–2025, promedio municipal con `00_clima_municipal.R`, mismo
criterio que Tmax. Comprobado antes de escribir esto: sin NA; mediana 1,000–1,270 Pa; en días con
Tmax ≥ 36 °C la humedad relativa (calculada con Tmax, cota superior) tiene mediana 26 % y p90 48 %,
y el punto de rocío mediana 15.4 °C: el calor extremo en México es mayoritariamente seco, pero hay
una cola húmeda (costas) que el modelo principal no distingue.

## I1. Temperatura aparente en lugar de Tmax

Temperatura aparente de Steadman (1984) a la sombra y sin viento: **AT = Tmax + 0.33·e − 4.0**, con
e = vp en hPa. Mismos cortes de 3 °C, misma referencia [24, 27), mismas ventanas 0, 1–3, 4–7, 8–14,
mismo modelo. Dos salidas por desenlace:
- acumulado 0–14 en el bin ≥ 36 °C de AT (comparable en rango, no en frecuencia: AT ≥ 36 es más común
  que Tmax ≥ 36);
- **BIC** de ambos modelos (Tmax y AT) sobre la misma muestra; se declara «mejor» la exposición con
  BIC menor por ≥ 10. Criterio fijado aquí; no se elige después.

Qué se espera: BIC parecido o levemente mejor con AT en infecciosas, endocrinas y genitourinario
(deshidratación, vectores); sin cambio en respiratorio y traumatismos.

## I2. Calor seco vs calor húmedo

Tmax en los mismos bins, pero los dos superiores se parten por punto de rocío del día:
**húmedo si Td ≥ 15 °C, seco si Td < 15 °C** (Td de vp por Magnus; 15 °C es la mediana en días
≥ 36 °C, fijada aquí). Doce bins: los ocho inferiores iguales, luego [33,36) seco, [33,36) húmedo,
[36,∞) seco, [36,∞) húmedo. Referencia [24,27). Ventanas y modelo iguales. Contraste comprometido:
**acumulado 0–14 húmedo − seco en [36,∞)** (diferencia de log-IRR con covarianza completa), por
desenlace, BH al 5 % sobre los 16 capítulos.

Qué se espera: húmedo > seco en infecciosas (A09, dengue), piel y endocrinas (menor evaporación);
sin diferencia en traumatismos; respiratorio igual de negativo en ambos. Si el seco supera al húmedo
en general, se reporta tal cual (sería evidencia de que el estrés térmico aquí es por radiación y
deshidratación, no por carga húmeda).

## I3. Desenlaces

Los 16 del principal (15 capítulos + total) para I1 e I2. Además, por su interés en H, los códigos
E86, A09, A90, A97, T63 y N23 en I2 (exploratorio, se reportan sin BH adicional).

## I4. Implementación

`25_clima_humedad.R` construye `clima_ventanas_at_2012_2025.parquet` y
`clima_ventanas_hum_2012_2025.parquet` (misma estructura que `clima_ventanas_2012_2025.parquet`;
`bp` idéntico). `06_modelo_rezagos.R` acepta `EXPO=tmax|at|hum` (sufijo `_expo-at`, `_expo-hum`) y
escribe el BIC en `_resumen.csv` para todas las corridas. Salidas:
`resultados/tablas/rezagos_expo-at_2012_2025.csv`, `rezagos_expo-hum_2012_2025.csv`,
`humedad_comparacion_2012_2025.csv` (BIC Tmax vs AT; húmedo − seco con q), figura 11.
