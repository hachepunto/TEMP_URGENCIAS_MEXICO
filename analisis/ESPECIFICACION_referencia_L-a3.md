# Especificación comprometida L-a3: ¿el gradiente inverso de mortalidad por calor es un artefacto de la referencia 24–27 °C?

Escrita el 2026-11-06, **antes de calcular ningún contraste de esta etapa**. No hay modelos nuevos: todo sale de los coeficientes y covarianzas que ya guardó `06` (`*_vcov.rds`) para L-a2 (`EXPO=fino`) y G (`EXPO=tmax`).

**Advertencia de origen.** La hipótesis se formó viendo las estimaciones puntuales de L-a2 (`mortalidad_dosis_curvas_2012_2025.csv`): la curva de M3 queda por debajo de la de M1 en todo 27–38 °C (todas a 33–36: 0.980 en M1, 0.898 en M3) y, medido desde 33–36, el salto a 36–38 es casi igual (1.08 y 1.07). Por eso el criterio no puede leerse como confirmación independiente: lo que aporta esta etapa es el intervalo de confianza de ese contraste y fijar de antemano qué cuenta como «explica».

## Hipótesis

El cociente M3/M1 < 1 no mide una menor vulnerabilidad al calor, sino que en M3 los días templados (24–27 °C) tienen una mortalidad relativamente más alta que los días cálidos. La curva de M3 es más honda o su mínimo está desplazado. Si es así, al medir el calor desde un día cálido no extremo el gradiente desaparece.

## Contraste principal

Por tercil de marginación, el log-IRR acumulado 0–14 de **36–38 °C frente a 33–36 °C**: diferencia de coeficientes acumulados (pesos 1, 3, 4 y 7 por ventana), con EE desde la covarianza completa del modelo del tercil. Cociente M3/M1 con EE por suma de varianzas (modelos independientes). Desenlaces: todas, circulatorio y todas ≥ 65; BH sobre los 3.

## Criterio fijado aquí (todas las causas)

- **Referencia**: IC 95 % del cociente incluye 1 y estimación puntual más cerca de 1 que 0.921.
- **No es la referencia**: cociente < 1 con IC que excluye 1 y ancho del IC del log-cociente < 0.4.
- **Inversión**: cociente > 1 con IC que excluye 1 (desde un día cálido, M3 sufre más).
- Cualquier otro patrón: **indeterminado**.

## Secundarios (no entran en el criterio)

1. Mismo contraste desde 33–36 para 38–40 y ≥ 40 (L-a2) y para el bin abierto ≥ 36 (modelos de G).
2. Dónde se forma el gradiente: M3/M1 del IRR de 27–30, 30–33 y 33–36 frente a 24–27 (G, `EXPO=tmax`). Si ya es < 1 a 33–36, el gradiente no es específico del calor extremo.
3. Referencia en la temperatura de mínima mortalidad (TMM) de cada tercil: el bin con menor IRR acumulado entre 24–27 y 33–36 en el modelo de L-a2, y el cociente M3/M1 de 36–38 frente a ese bin. La TMM se elige con los datos, así que su IC es optimista; se reporta para describir la curva, no para decidir.

Límites declarados: (i) el contraste 36–38 frente a 33–36 es más pequeño que frente a 24–27 y tendrá menos potencia; si sale indeterminado por ancho, se dice así y no se lee como «explica»; (ii) no identifica por qué los días templados pesan más en M3 (estacionalidad residual dentro del mes, frío, tipo de clima); eso sería otra etapa.

## Implementación

`37_mortalidad_referencia.R` → `resultados/tablas/mortalidad_referencia_2012_2025.csv` (contrastes y criterio) y `_forma_` (secundario 2); `32` añade el grupo L-a3 a la figura 12.
