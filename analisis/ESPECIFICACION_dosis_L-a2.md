# Especificación comprometida L-a2: ¿el gradiente inverso de mortalidad por calor es un efecto de dosis dentro del bin abierto ≥ 36 °C?

Escrita el 2026-11-04, **antes de construir la exposición y de correr ningún modelo de esta etapa**. Motivación: L-a (`ESPECIFICACION_aclimatacion_L.md`) dio «explica» por su criterio (todas a p ≥ 99 local, M3/M1 1.020 [0.947, 1.104]), pero los descriptivos de interpretación mostraron que el bin abierto ≥ 36 °C es más caliente en M1 (mediana 37.7 frente a 36.8 °C; ≥ 40 °C en 16.1 % frente a 2.9 % de esos días). El umbral local corrige a la vez la rareza del día y esa diferencia de dosis, así que L-a no separa aclimatación de dosis. Las dos hipótesis predicen cosas distintas a la misma temperatura absoluta: si es dosis, el gradiente desaparece; si M1 está aclimatado (36 °C es habitual allí), M1 debería sufrir menos y el cociente M3/M1 subir por encima de 1; si el cociente sigue < 1, queda una menor vulnerabilidad aparente de M3 que ni la dosis ni la aclimatación explican.

Único vistazo previo (sólo exposición, sin desenlaces): días-municipio 2012–2024 por tercil M1/M2/M3 en 36–38 °C 140,778 / 104,524 / 91,363 (606/602/661 municipios), en 38–40 69,185 / 26,762 / 16,140, en ≥ 40 40,247 / 7,737 / 3,156. Dentro de 36–38 la mediana de Tmax es 36.83 / 36.68 / 36.62 °C: la dosis queda igualada a 0.2 °C.

## Exposición

Tmax absoluta con los mismos cortes de 3 °C de `05` hasta 36 y el bin abierto partido: `[36,38)`, `[38,40)`, `[40, Inf)` (12 bins, referencia `[24,27)`). Misma serie, mismas ventanas (0, 1–3, 4–7, 8–14), misma precipitación y mismo panel. `06` la usa con `EXPO=fino`.

## Modelo y contrastes

El de G (Poisson FE `cve^anio^mes + ent^dow`, EE por municipio, 2012–2024), acumulado 0–14 frente a `[24,27)`. Desenlaces: todas, circulatorio y todas ≥ 65. Nacional y por tercil (`MARG=1,2,3`); cociente M3/M1 con EE por suma de varianzas; BH sobre los 3 cocientes del contraste principal.

Contraste principal: **todas a `[36,38)`**, el único tramo con dosis igualada y días suficientes en M3.

## Criterio fijado aquí

- **Dosis**: IC 95 % del cociente incluye 1 y estimación puntual más cerca de 1 que 0.921.
- **Persiste** (ni dosis ni aclimatación lo explican): cociente < 1 con IC que excluye 1 y ancho del IC del log-cociente < 0.4.
- **Aclimatación neta de M1**: cociente > 1 con IC que excluye 1.
- Cualquier otro patrón: **indeterminado**.

Secundario (no entra en el criterio): cocientes en `[38,40)` y `[40, Inf)` (en M3 `[40, Inf)` tiene pocos días y se espera impreciso), circulatorio y ≥ 65; mediana de Tmax por bin y tercil para documentar la igualación de dosis.

Límites declarados: (i) 36–38 °C en M1 y M3 puede ser igual de caliente pero no igual de raro, así que «dosis» y «aclimatación» se leen por el signo del cociente, no se estiman por separado; (ii) los municipios que aportan a 36–38 no son todos los de cada tercil (los fríos no llegan), igual que en G.

## Implementación

- `35_clima_fino.R` → `datos/derivados/clima_ventanas_fino_2012_2025.parquet`.
- `06_modelo_rezagos.R`: `EXPO=fino`.
- `36_mortalidad_dosis.R`: cocientes y criterio → `mortalidad_dosis_2012_2025.csv`; `32` añade el grupo L-a2 a la figura 12.
