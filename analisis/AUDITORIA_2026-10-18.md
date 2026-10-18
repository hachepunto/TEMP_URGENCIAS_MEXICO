# Auditoría independiente — temperatura, urgencias y mortalidad (2026-10-18)

Revisor: agente independiente. Alcance: `/scratch/home/hachepunto/temp_urgencias/repo`, rama `main`,
commit `b9c2421` (más archivos sin versionar en `analisis/logs/`). No se modificó ningún archivo del
repo. Scripts de comprobación en `scratchpad/` (`a1.R` … `a15.R`), con 8 hilos; el único ajuste
`fepois` fue sobre un subconjunto 2012–2014 (a3.R). La auditoría previa (`AUDITORIA_2026-10-17.md`)
se leyó y no se repite lo que ya estaba cerrado.

## Resumen

- **Bloqueante (mortalidad, especificación G):** `19_leer_defunciones.R` se salta en silencio los
  años de registro 2018 y 2021 (vienen como zip dentro de zip). El panel de defunciones tiene 17 323
  muertes en 2018 y 19 593 en 2021, frente a ~700 k y ~1.1 M esperadas. Todos los resultados de
  mortalidad (`rezagos_defunciones_2012_2025.csv`, commit `a9a4ce7`) están calculados sobre 11 años
  de registro, no 13, y con artefactos dentro de cada mes.
- **Importante (todas las corridas de urgencias):** como los archivos DGIS 2012–2015 van del 26 de
  diciembre al 25 de diciembre, al excluir el archivo 2013 quedan **ceros explícitos falsos** en el
  26–31 de diciembre de 2012 (1 674 municipios) y en el 1–25 de diciembre de 2013 (1 481 municipios).
  Esas celdas mun×año×mes no se eliminan, porque tienen casos en los demás días, y meten un escalón
  dentro del mes. En un ajuste 2012–2014 esto mueve mucho el bin frío (<12 °C) y casi nada el ≥ 36.
- **Importante (H4-E):** `24` no aplica la regla de identificación comprometida (≥ 2 000
  municipio-días, ≥ 50 municipios; si no, usar [33,36)). En su lugar descarta con un criterio
  post hoc (EE > 1) que además deja pasar un IRR de 1e72. En C1, 13 de los 20 códigos **nunca se
  corrieron**, porque `06` aborta en el primer fallo; el commit `8c41811` lo atribuye a
  colinealidad.
- **Importante (lanzador):** a `relanzar_codigos_pendientes.sh` le falta la protección contra
  listas vacías: con 0 o 1 pendientes, un lote queda vacío y `06` corre los 164 códigos.
- **Importante (README):** la columna «Mismo día» del README no coincide con la tabla en 11 de 16
  capítulos. El acumulado sí coincide en 16/16.
- Fuera de eso, la mecánica nueva es correcta: AT, punto de rocío, partido seco/húmedo en 12 bins,
  contraste húmedo − seco con covarianza completa, BH y DerSimonian–Laird (incluidas τ² = 0 y la
  rama `global`), cociente M3/M1, BIC sobre la misma muestra, recorte de defunciones a 2024-12-31.
  Todo eso lo verifiqué.

---

## 1. Hallazgos

### Bloqueantes

**B1. Faltan los años de registro 2018 y 2021 de defunciones (zip anidado ignorado).**
- Dónde: `analisis/19_leer_defunciones.R:23-27`. `ms <- grep("\\.csv$", unzip(z, list = TRUE)$Name …)`
  sólo busca CSV en el primer nivel. `DEFUN_2018.zip` contiene `Defunciones_2018/def18.zip` y
  `DEFUN_2021.zip` contiene `Registro de defunciones 2021/DEFUN_2021.zip` (verificado con
  `unzip -l`). Para esos dos años `ms` queda vacío y `rbindlist(list())` no dice nada. La validación
  de `:28-35` es por archivo leído, así que no detecta un año ausente.
- Evidencia:
  - La tabla `val` del log `19_leer_defunciones.log` lista 11 archivos y ninguno es de 2018 ni de
    2021.
  - El descriptivo de golpe de calor del log 20 salta de 2017 a 2019 y de 2020 a 2022.
  - Defunciones por año de ocurrencia en `defunciones_2012_2024.parquet` (a5.R): 2017 689 424,
    **2018 17 323**, 2019 744 129, 2020 1 071 975, **2021 19 593**, 2022 843 249.
  - Lo que queda de 2018/2021 son registros tardíos (ocurridos en 2018 y registrados en 2019). Por
    eso hay un gradiente dentro del mes: 2018-12-01: 92 muertes, 2018-12-31: 1 955.
  - A la vez, el final de diciembre de 2017 y de 2020 queda corto, porque sus registros tardíos
    estaban en los archivos de 2018 y 2021: 31-dic-2017 = 467 frente a ~1 900 en días previos;
    31-dic-2020 = 1 947 frente a ~3 800.
- Consecuencia: el modelo G se estimó con 2 de 13 años casi vacíos y con escalones dentro del mes
  en dic-2017, dic-2018, dic-2020 y dic-2021, que los FE mun×año×mes no absorben. Las cifras del
  commit `a9a4ce7` (todas 1.095, circulatorio 1.121…) no son válidas. Además, 2021 es el segundo año
  de exceso COVID: su ausencia cambia la composición del periodo.
- Corrección:
  1. Descomprimir el zip interno (`unzip -p` del zip externo a un temporal y listar su contenido).
  2. Añadir `stopifnot` sobre el número de archivos por año de registro y sobre las defunciones por
     año de ocurrencia (p. ej. > 500 k).
  3. Volver a correr 19, 20 y `06 CONTEOS=defunciones`.
- Además (menor, inevitable): las muertes de 2024 registradas en 2025 faltan. Ene-2024 tiene 77 478
  y dic-2024 62 628. Conviene decirlo o cortar en 2024-11-30 como sensibilidad.

### Importantes

**I1. Días con cero falso en dic-2012 y dic-2013 por el corte de los archivos DGIS (afecta a todos
los modelos de urgencias).**
- Dónde: `01_leer_urgencias.R:6-8,18-20` excluye el archivo 2013 entero. El comentario dice
  «Diciembre de 2013 sí entra (viene del archivo 2014)». Después, `05_insumos_capitulos.R` (y 08, 15
  y 21, que usan el mismo parquet) rellena con ceros todos los días que no tienen filas.
- Evidencia (a1.R, a3.R): los archivos 2012–2015 cubren del 26-dic del año anterior al 25-dic.
  - Fechas de dic-2012 en el parquet: sólo hasta el 25-dic (20 206 ese día) y **ninguna fila del
    26 al 31**.
  - Dic-2013: **sólo del 26 al 31** (148 308 filas, del archivo 2014) y 2 filas sueltas.
  - Dic-2014: días 1–25 del archivo 2014 y días 26–31 del archivo 2015; ese mes queda completo.
  - En `conteos_capitulos` (total): dic-2012 tiene casos en 1 674 municipios y dic-2013 en 1 481.
    Esas celdas `cve^anio^mes` sobreviven a `fepois` con 6 y 25 días de cero falso.
- Magnitud: ajuste del modelo principal sobre 2012–2014 (3 años; la contaminación es ~4× mayor que
  en el periodo completo). Se compara el pipeline con la misma estimación quitando esos 31 días:

  | Desenlace | Bin | Pipeline | Sin días artefacto |
  |---|---|---|---|
  | total | <12 acum. | 0.647 (EE 0.165) | 0.778 (EE 0.110) |
  | total | ≥36 acum. | 1.064 (EE 0.030) | 1.064 (EE 0.026) |
  | respiratorio | <12 acum. | 0.709 (EE 0.225) | 0.863 (EE 0.173) |
  | traumatismos | <12 acum. | 0.463 (EE 0.146) | 0.575 (EE 0.095) |
  | traumatismos | ≥36 acum. | 1.157 (EE 0.030) | 1.158 (EE 0.028) |

  Los finales de diciembre son fríos, así que el artefacto empuja el bin frío hacia abajo e infla
  su EE. El ≥ 36 casi no cambia. En el periodo completo, la sensibilidad `desde2014` (sin 2012 ni
  dic-2013, así que libre del artefacto) desplaza el <12 entre +0.003 y +0.038 y el [15,18) hasta
  −0.064. No separé cuánto de eso es artefacto y cuánto es el cambio de periodo.
- Por qué importa: el titular (≥ 36) se sostiene. Lo que queda contaminado es el contraste
  comprometido `frio_12` de H (12/164 con q < 0.05), el lado frío de las curvas y la lectura de
  «frío < 12 negativo».
- Corrección: en `05`/`06` excluir del panel 2012-12-26..31 y todo dic-2013 (o declarar el periodo
  como 2012-01-01..2012-12-25 + 2014-01-01..2025-12-31). Añadir en `01`/`05` un chequeo de casos por
  día (p. ej. `stop` si un día tiene < 10 % de la mediana de su mes). Volver a correr. Corregir el
  comentario de `01:8`.

**I2. H4-E: no se implementa la regla de identificación comprometida; filtro post hoc defectuoso;
13 de 20 códigos sin correr en C1.**
- Dónde: `24_codigos_marginacion.R:42-46` y `logs/lanzar_codigos_marginacion.sh:19-21`;
  `06_modelo_rezagos.R:79`.
- Lo que dice la especificación: H4 dice «E: a clima de base constante … como en la
  especificación E». E dice que el bin ≥ 36 se interpreta sólo en celdas con ≥ 2 000 municipio-días
  y ≥ 50 municipios; si no, se marca «no identificado» y se usa [33,36). `14_figura_clima_marg.R:17-18`
  sí lo hace con `celdas_clima_marg.csv`. `24` no lee esa tabla, no reporta [33,36) y aplica
  `se > 1` como regla nueva.
- Evidencia:
  - `celdas_clima_marg.csv`: C1×M1/M2/M3 tienen 174/185/200 días ≥ 36, todas `FALSE`.
  - Los logs `06_codigos_clima1_marg{1,2,3}` muestran 6 códigos ajustados (E86, E87, R04, A97, N23,
    J21). Al llegar al 7.º (A90) aparece `Error: all(regs %in% names(b)) is not TRUE` y
    `Execution halted`. Los 13 restantes (T63, J00, J20, R50, N20, J46, J04, J98, J22, J31, J96,
    J45, I50) **no se intentaron** (6 CSV por directorio C1).
  - El commit `8c41811` dice «14/20 fallan por colinealidad». Falso: falla 1 y 13 no se corren.
  - El filtro `se ≤ 1` deja pasar estimaciones degeneradas. En `codigos_clima_marg_2012_2025.csv`,
    A90 en C2×M3 tiene IRR = 1.0e72 con EE = 0.91 (coef ≈ 166). En C1 hubo coeficientes de −51 y
    −75 con EE de 4–6.
  - El mensaje «20 códigos × 9 estratos» es falso: C1 tiene 0 filas.
- Corrección:
  1. Usar `ge36_identificado` de `celdas_clima_marg.csv` y reportar [33,36) donde no se identifica,
     como en 14.
  2. En `06`, envolver cada desenlace en `tryCatch` y registrar el fallo en vez de abortar el lote.
  3. Marcar como no identificadas las estimaciones con |coef| grande (p. ej. > 5), no sólo las de
     EE grande.
  4. Corregir el mensaje de commit/registro.

**I3. `relanzar_codigos_pendientes.sh` puede correr los 164 códigos por accidente.**
- Dónde: `analisis/logs/relanzar_codigos_pendientes.sh:11-13`.
- Escenario: si al terminar los lotes 0/1 quedan 0 o 1 códigos pendientes, `split -n l/2` crea
  `lote2_codigos_00`/`_01` vacíos. `$(cat …)` se expande a nada y `06` sin argumentos corre `todos`
  (los 164), dos veces en paralelo y sobrescribiendo los CSV. Verificado: con entrada vacía,
  `split -n l/2` produce `v_00` y `v_01` de 0 bytes; con un código, `u_01` queda en 0 bytes. En la
  corrida real hubo 75 pendientes y no ocurrió. `lanzar_codigos_marginacion.sh:15` sí tiene la
  guarda.
- Corrección: `[ -s "logs/lote2_codigos_0$k" ] || continue` antes de lanzar, o hacer que `06` aborte
  si `CONTEOS=codigos` y no hay argumentos.

**I4. La columna «Mismo día» del README no sale de la tabla que cita.**
- Dónde: `README.md`, tabla de «Estado», que cita `rezagos_2012_2025.csv`.
- Evidencia (a7/a8.R): v0, bin ≥ 36. README frente a tabla:
  - Infecciosas 1.126 vs **1.121**; Endocrinas 1.133 vs 1.135; Genitourinario 1.070 vs 1.069.
  - Sangre 1.066 vs 1.068; Piel 1.063 vs 1.059; Traumatismos 1.113 vs **1.118**.
  - Síntomas 1.071 vs 1.072; Ojo 1.039 vs 1.038; Mentales 1.099 vs 1.100; Nervioso 1.041 vs 1.044.
  - Osteomuscular 1.031 vs 1.033.

  Coinciden: total 1.067, circulatorio 0.979, respiratorio 1.028, oído 1.023, digestivo 1.011.
  Tampoco salen de la versión con 2013 (`historico/…/rezagos_2012_2025.csv`: infecciosas 1.120)
  ni de la versión versionada en `05dfae4`, que es idéntica a la actual. No encontré el origen. El
  acumulado 0–14 coincide en 16/16.
- Corrección: regenerar la tabla del README desde el CSV (con código, no a mano).

**I5. Especificación G entregada a medias.**
- Lo comprometido: (i) curva de mortalidad frente a urgencias y (ii) gradiente por marginación en
  mortalidad (D sobre defunciones, todas las causas y circulatorio). No hay corridas
  `CONTEOS=defunciones MARG=k`, ni script, ni tabla. El README no menciona la mortalidad. Hay que
  rehacerlo de todos modos por B1.

### Menores

**M1. `06b_juntar_rezagos.R:9` tiene los 10 niveles fijos.** Con `_expo-hum` (12 bins), las
etiquetas «[33,36) seco/húmedo» y «[36, Inf) seco/húmedo» pasarían a `NA` en el `factor`. Hoy no
afecta: `rezagos_expo-hum_2012_2025.csv` lo escribió `06` y tiene 960 filas, 12 bins y 0 NA. Tomar
`niveles` de los datos o según el sufijo.

**M2. `21_insumos_codigos.R:15`: `mun_dias` se desborda.** `cve * 100000L` es entero de 32 bits.
Con cve > 21 474 da NA (log: «50 or more warnings»). Los 164 valores de `mun_dias` en
`codigos_incluidos.csv` están mal (A09: 1 099 436 frente a 1 572 814 recontado). No se usa aguas
abajo. Usar `uniqueN(.(cve, fecha))`.

**M3. `21` no filtra fechas.** Incluye 91 069 filas con fecha NA o fuera de 2012–2025 (dic-2011 del
archivo 2012, fechas absurdas de 2017). Verificado: la lista de 164 códigos no cambia con el
filtro, y `06` ignora esas filas al unir por `(cve, fecha)` con el clima.

**M4. `22_codigos_fdr.R:26-31,37`: la media de contracción usa pesos de efecto fijo.** El código
usa μ = Σ(β/se²)/Σ(1/se²), no el μ de efectos aleatorios con pesos 1/(se²+τ²). La especificación no
fija μ, pero lo estándar en un modelo normal-normal con τ² de DerSimonian–Laird es el ponderado por
1/(se²+τ²). Con pesos FE, en infecciosas manda A09 (μ 0.152 frente a 0.250 RE) y en circulatorio
I10 (−0.125 frente a −0.045). Efecto en el calor: A90 1.50 frente a 1.58 y A97 1.64 frente a 1.68;
el top-20 por |β̃| no cambia. Lo demás está bien: τ² DL con piso 0 (recalculado, mismo valor), τ² = 0
→ β̃ = μ, rama `global` con todos los códigos del contraste para ojo, sangre, tumores, perinatal y
covid, y BH por contraste (diferencia máx. 6e-16).

**M5. Agrupación por capítulo, no por letra.** La especificación dice «por capítulo (letra del
código)». El código agrupa por `capitulo` de 21, así que D separa tumores y sangre, H separa ojo y
oído, y S/T quedan juntos. Es razonable, pero hay que declararlo.

**M6. El 15 °C no es la mediana del punto de rocío en días ≥ 36.** `ESPECIFICACION_humedad.md` (I2)
dice «15 °C es la mediana en días ≥ 36 °C». El log de 25 da 38.4 % de días húmedos (2011–2025) y el
parquet de 2012–2025, 39.7 %. El partido real es 62/38, no 50/50. El código implementa bien el
umbral fijado. Lo que hay que corregir es el texto (y el manuscrito, si lo repite).

**M7. Versiones de Daymet mezcladas en 25.** Tmax 2011–2022 viene de V4.0 (`day_results`) y vp
2011–2022 de V4R1. Es coherente con lo validado (V4.0 ≈ V4R1 en 2022), pero hay que declararlo.

**M8. 05b recorta enero de 2012 sin necesidad.** El comentario dice «desde 2012-01-31 para que las
ventanas de 30 días estén completas», pero 2011 está cargado: las ventanas están completas desde el
2012-01-01. `v30` no usa la misma muestra que el principal (le falta ene-2012), y conviene saberlo
al compararlas.

**M9. Mensajes de commit con afirmaciones inexactas** (detalle en la tabla de cifras):
- `9bed3e0`: «cambios ≤ 0.015». En ≥ 36, sangre cambia 0.024; en otros bins, hasta 0.064.
- `bfa8727`: la frase sobre el frío nombra A90 0.19 y Z48/Z51 junto a los 12 significativos, pero
  esos tres tienen q = 0.16, 0.057 y 0.057.
- `8c41811`: lo de «14/20 por colinealidad» (ver I2).

**M10. README desactualizado.** «Estructura» y «Reproducir» no mencionan 18–26, `05b`/`06b`, las
variables `VENTANAS`, `ANIO_MIN`, `EXPO` ni `CONTEOS=defunciones|codigos`, ni los lanzadores.
«Sensibilidad de efectos fijos: efectos del calor a la mitad» es optimista: con FE A el log-IRR ≥ 36
del total pasa de 0.037 a 0.001, el de infecciosas de 0.167 a −0.013 y el de mentales de 0.083 a
−0.001, y digestivo y osteomuscular cambian de signo. «A la mitad» sólo vale para la mediana.

---

## 2. Revisado y correcto

- **06 (completo):**
  - Sufijos.
  - Selección del parquet según `VENTANAS`/`EXPO`, y prohibición de v30 con AT/hum.
  - Recorte de defunciones a 2024-12-31 (n_obs + eliminadas = 11 668 293 = 2 457 × 4 749 días).
  - `ANIO_MIN`.
  - Unión de conteos por `(cve, fecha)` y ceros explícitos.
  - Regresores y referencia para 10 y 12 bins.
  - Acumulado = Σ días × β con la `V` completa (pesos 1,3,4,7; con v30, 1,3,4,7,7,9).
  - EE bidireccionales.
  - `stop` ante `NA`.
  - `vcov` guardada como `V[regs, regs]` con `attr(coef)`.
  - BIC en `_resumen`.
  - `n_mun`/`casos` sobre `obs(f)`.
  - La versión versionada de `rezagos_2012_2025.csv` es idéntica entre `05dfae4` y HEAD
    (`git diff --stat` vacío). Confirma «coeficientes sin cambio» de `b9c2421`.
- **25:**
  - AT = Tmax + 0.33·vp/100 − 4: recalculé 2020 desde los `.rds` (896 805 municipio-días) y
    coincide el 100 % con el bin del parquet.
  - Magnus (243.04, 17.625, 610.94 Pa) correcto.
  - `bin_hum`: verifiqué en v0 y v8_14 que los bins 1–8 son iguales al base, 9 = 9 + 10 y
    10 = 11 + 12. El orden 9/10 = [33,36) seco/húmedo y 11/12 = ≥ 36 seco/húmedo coincide con
    `niveles` de `06:27`.
  - 31-dic bisiesto imputado (2020-12-31 presente en los 2 457 municipios), `nrow(out) == nrow(base)`
    y ventanas que suman sus días.
- **26:**
  - Contraste húmedo − seco: pesos +w en b12 y −w en b11 por ventana, con la `V` completa.
    Coherente con la tabla: log(1.270) − log(1.149) = 0.100 → 1.105.
  - BH sobre los 16 capítulos.
  - `stopifnot` de misma muestra Tmax/AT (pasa).
  - Regla de BIC ±10 como en la especificación.
- **22:**
  - 164 códigos por contraste; BH dentro del contraste con Z incluidos.
  - DL recalculado (mismo τ² en los 32 grupos × contraste).
  - Media posterior recalculada (diferencia máx. 6e-16).
  - τ² = 0 → μ.
  - Grupos con < 3 códigos → `global`.
  - La FDR se prueba sobre β̂/se y el ranking usa β̃.
- **24-D:**
  - 62 códigos = los no-Z con q < 0.05 (64 menos Z71 y Z48).
  - log-cociente M3 − M1 con EE √(EE₁² + EE₃²) y BH sobre los 62; ningún NA en q.
- **21:**
  - Umbral de 100 000: 164 códigos, 85.75 % de las atenciones; ningún código cruza el umbral si se
    filtran las fechas.
  - Rangos de capítulo por cadena sin solapes (`stopifnot` de «otro»).
- **20:** rangos A00–Z99, A00–R99, I, J, N17–N19, E00–E90 y V01–Y98, según la especificación.
- **19:** validación de MUNRESIDENCIA por archivo (`mun==ent` 2.5 %, más de 5 000 claves). Sirve
  para lo que lee; el problema está en lo que no lee (B1).
- **05b:** ventanas 0–30 por llave `(cve, fecha)`, 31-dic imputado y suma de días por ventana
  comprobada.
- **lanzar_codigos_marginacion.sh:** guarda contra lista vacía; D con todos los significativos no-Z
  y E con el top-20 por |β̃| (62 > 50, como dice la especificación).
- **01:** la validación por año (mun==ent ≤ 10 %, ≥ 1 500 municipios) funciona: todos los años
  tienen 2.45–3.37 % y 2 371–2 463 municipios.
- Tablas de resultados (`rezagos*_2012_2025.csv` y `_resumen`): 0 NA en las 10 variantes; 16, 164,
  7, 5 o 3 desenlaces según corresponde; 12 bins en `expo-hum`.
- Estimaciones degeneradas en el barrido nacional por código: sólo A90/A97 en bins fríos con
  EE 0.5–1.45; ninguna en ≥ 36. En `marg1..3` (D), ningún acumulado ≥ 36 con EE > 0.5.

## 3. Cifras cotejadas

| # | Fuente | Cifra reportada | Valor en la tabla | ¿Coincide? |
|---|---|---|---|---|
| 1 | README | Infecciosas mismo día 1.126 | 1.121 (`rezagos_2012_2025.csv`, v0, ≥36) | **No** |
| 2 | README | Traumatismos mismo día 1.113 | 1.118 | **No** |
| 3 | README | Endocrinas / Nervioso / Piel mismo día 1.133 / 1.041 / 1.063 | 1.135 / 1.044 / 1.059 | **No** (11/16 filas difieren) |
| 4 | README | Infecciosas acum. 1.182 [1.146, 1.219] | 1.182 [1.146, 1.219] | Sí |
| 5 | README | Respiratorio acum. 0.783 [0.756, 0.811] | 0.783 [0.756, 0.811] | Sí |
| 6 | README | Circulatorio 0.979 / 0.897 [0.868, 0.928] | 0.979 / 0.897 [0.868, 0.928] | Sí |
| 7 | README | Total 1.067 / 1.038 [1.020, 1.056] | 1.067 / 1.038 [1.020, 1.056] | Sí |
| 8 | README | E86 2.11 [1.91, 2.33]; N17 0.94 [0.74, 1.19]; I21 0.99 [0.84, 1.16] | iguales (`rezagos_subgrupos_2012_2025.csv`) | Sí |
| 9 | README | Hospital: dif. < 0.03 salvo sangre y mentales | sangre +0.051, mentales −0.035, resto ≤ 0.027 | Sí |
| 10 | README | FE A: frío < 12 negativo en todos | 16/16 negativos (`rezagos_fe-anio_semana`) | Sí |
| 11 | README | FE A: «efectos del calor a la mitad» | razones log-IRR −1.28 a 2.0; total 0.02, infecciosas −0.08 | Engañoso |
| 12 | README | 2015/2018: 72 y 20 líneas descartadas | 72 y 20 (`01_…log`) | Sí |
| 13 | `a9a4ce7` | Mortalidad todas 1.095 [1.068, 1.123]; renal 0.983; externas 1.158 | iguales (`rezagos_defunciones…`) | Sí (pero datos incompletos, B1) |
| 14 | `9bed3e0` | desde2014: cambios ≤ 0.015, ningún signo cambia | máx. 0.024 (sangre) en ≥36; sin cambios de signo en ≥36 | **No** (cifra) / Sí (signo) |
| 15 | `9bed3e0` | v30: infecciosas 1.131, respiratorio 0.652, total 1.027 | 1.131, 0.652, 1.027 | Sí |
| 16 | `bfa8727` | 64/164 con q < 0.05 (44 suben, 20 bajan); Z 2/11 | 64 (44/20); Z 2/11 | Sí |
| 17 | `bfa8727` | E86 2.11, E87 1.88, R04 1.75, T63 1.52, R50 1.41, J21 0.63, J00 0.68, I10 0.86, Z34 1.03 | 2.113, 1.878, 1.754, 1.519, 1.405, 0.630, 0.678, 0.861, 1.027 | Sí |
| 18 | `bfa8727` | 14/15 respiratorios bajan | 14/15 | Sí |
| 19 | `bfa8727` | Frío 12/164; «dengue 0.19–0.21, Z04/Z48/Z51 0.55–0.65» | 12/164; A90 0.187 (q = 0.16), Z48/Z51 q = 0.057 no significativos | Parcial |
| 20 | `f0cccea` | Piloto T63 1.519 [1.438, 1.603] | 1.519 [1.438, 1.603] (barrido final) | Sí |
| 21 | `8c41811` | D: 62 códigos, mediana 0.97; T63 0.63 [0.53, 0.75], M1 1.63, M3 1.03 | 62; 0.970; 0.632 [0.530, 0.753]; 1.632; 1.031 | Sí |
| 22 | `8c41811` | E: T63 en C3 0.54 [0.37, 0.78] | 0.535 [0.367, 0.780] | Sí |
| 23 | `8c41811` | C1: «14/20 fallan por colinealidad» | 1 falla (A90), 13 sin correr | **No** |
| 24 | `b9c2421` | AT mejor en 11/16; ΔBIC total −948, trauma −626, síntomas −533, infecciosas −320, respiratorio +507 | 11/16; −948, −626, −533, −320, +507 | Sí |
| 25 | `b9c2421` | Infecciosas húmedo 1.27 vs seco 1.15, cociente 1.105 | 1.270 / 1.149 / 1.105 (q = 0.00084) | Sí |
| 26 | `b9c2421` | A97 2.68 húmedo vs 1.23 seco, 2.17 [1.81, 2.61] | 2.676 / 1.231 / 2.174 [1.811, 2.611] | Sí |
| 27 | log 21 / espec. H | 164 códigos, 85.7 % | 164; 85.75 % | Sí |
| 28 | espec. I2 | Td = 15 °C es la mediana en días ≥ 36 | 38.4–39.7 % húmedos | **No** |

## 4. Lo que no pude revisar

- **Resultados corregidos.** No reajusté modelos completos (instrucción del encargo). El impacto de
  I1 está medido en un subconjunto de 2012–2014; el de B1 no se puede medir sin leer los zips
  anidados y volver a correr 19, 20 y 06.
- **Contenido de los zips internos de 2018/2021.** No los descomprimí, así que no sé si su formato
  es compatible con `leer_csv` (nombres de columna, codificación).
- **Figuras** (07, 10, 12, 14, 16, 17, 18, 23, 24, 26): sólo revisé que dibujan desde las tablas;
  no las abrí.
- **vp de Daymet V4R1 frente a V4.0.** No comparé presión de vapor entre versiones (V4.0 vp no se
  descargó). La AT la validé sólo para 2020.
- **Mediana real del punto de rocío** en días ≥ 36 (para reconciliar M6): habría que leer los 15
  `.rds` de vp por NFS. Me quedé con la proporción del log y del parquet.
- **Municipios creados después del shapefile** (02006 San Quintín, etc., 47 735 atenciones):
  pendiente desde la auditoría previa (I1 de entonces); no lo volví a evaluar.
