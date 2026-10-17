# Auditoría independiente — temperatura y urgencias (2026-10-17)

Revisor: agente independiente (CC-fx-ld1, sesión de auditoría). Alcance: rama `reorganizacion`,
estado del árbol a las 10:50 del 2026-10-17 (commit `c3e44bf` + archivos sin commit: `06` modificado,
`08`–`12` nuevos). Durante la auditoría estaban corriendo la sensibilidad A (`FE_SPEC=anio_semana`)
y los terciles de marginación (`MARG=1..3`); sus resultados no se auditan aquí salvo lo que ya
estaba en los logs. No se modificó ningún archivo del repo; los scripts auxiliares están en
`scratchpad/auditoria/` (`a_cifras.R`, `b_urgencias.R`, `c_clima.R`, `d_conteos.R`, `e_modelo.R`,
`f_fe_removidos.R`, `g_cluster.R`, `h_2013.R`, `i_sin2013.R`) y se corrieron con `NHILOS=4`.

## Resumen ejecutivo

1. **Hay un error bloqueante en los datos de 2013.** En el archivo crudo `URGENCIAS_2013.csv` la
   columna `MUNRESIDENCIA` es una copia de `ENTRESIDENCIA` con ceros a la izquierda (`"11";"011"`,
   `"03";"003"`, `"09";"009"`): el 100 % de las 10.0 M atenciones de 2013 con estado válido tiene
   `mun_res == ent_res`. El pipeline (`01`, `05`) no lo detecta y asigna todo 2013 a 28 municipios
   falsos (01001, 02002, …, 32032; los de los estados 22, 23, 25 y 27 no existen y se descartan en
   silencio como «sin clima»). Enero–noviembre de 2013 pone 5.97 M casos (7.7 % del total de los 15
   capítulos) en 28 celdas municipio-año con la Tmax de un solo municipio (p. ej. todo el Estado de
   México en 15015 Atizapán, toda la CDMX en 09009 Milpa Alta). Esas celdas tienen pesos enormes en
   la verosimilitud Poisson. Hay que excluir 2013 (o recuperar un archivo 2013 correcto) y
   **recorrer todo** (piloto, rezagos, sensibilidad, subgrupos, marginación) antes de reportar nada.
   La buena noticia: recorrí el modelo principal sin 2013 en tres capítulos (circulatorio,
   respiratorio, traumatismos) y las estimaciones apenas se mueven (acumulado ≥ 36: 0.900 → 0.893,
   0.775 → 0.775, 1.132 → 1.119), así que lo más probable es que los resultados se sostengan; pero
   no se puede afirmar hasta recorrer los 16 (hallazgo B1).
2. Fuera de eso, la mecánica del pipeline es correcta: uniones por llave, ceros explícitos, rezagos
   reconstruidos por `(cve, fecha)` y verificados contra los `.rds` originales, 31-dic bisiesto
   imputado, rangos CIE-10 sin solapes, fórmula igual a la especificación, acumulado 0–14 con la
   matriz de varianzas completa, figuras que sólo dibujan. Todas las cifras del README que pude
   cotejar coinciden con las tablas.
3. Lo que `fepois` elimina son exactamente las celdas municipio×año×mes sin casos (sin singletons);
   eso no sesga el estimador condicional, pero la sobredispersión existe (var/media ≈ 3.5 en
   circulatorio) y la inferencia depende sólo del agrupamiento por municipio; agrupar por estado o
   por municipio+fecha ensancha los intervalos (hallazgo I4).
4. Hay problemas de interpretación que un revisor señalará: el 26 % sin municipio en 2012 está
   concentrado por estado (Colima, Q. Roo, Tamaulipas, Hidalgo casi al 100 %); 2024–2025 cambia de
   fuente (67 % de las atenciones pasan a CLUES `IMB`) con caídas de volumen de 20–40 % en varios
   estados; el efecto de ≥ 36 °C se identifica en 1 869 municipios (588 nunca llegan) y en 7 estados
   del norte y del Golfo; el modelo no distingue desplazamiento más allá de 14 días.

## Hallazgos

### Bloqueantes

**B1. `MUNRESIDENCIA` de 2013 no contiene el municipio de residencia.**
- Dónde: datos crudos `URGENCIAS_2013.csv` (columnas 8–9); `01_leer_urgencias.R:43` lo lee tal cual;
  `02_panel.R:52-59` y `05_insumos_capitulos.R:36-40` construyen `cve = ent*1000 + mun` sin ninguna
  comprobación de que el municipio exista en el estado.
- Cómo lo comprobé: `h_2013.R` sobre `urgencias_2012_2025.parquet`: % de atenciones con
  `mun_res == ent_res` por año: 2012 3.03 %, **2013 100.00 %**, 2014 3.07 %, …, 2025 3.02 %. En 2013
  cada estado tiene exactamente un municipio con casos. En el crudo: `grep '"BSSSA' URGENCIAS_2013.csv`
  → `"03";"003"` en todas las filas; `head -3000000 | cut -f8,9` → `"15";"015"` 1.19 M, `"14";"014"`
  604 k, `"11";"011"` 509 k. `d_conteos.R`: en 2013 el 10.39 % de las atenciones con residencia
  «válida» cae fuera del shapefile (claves 27027, 25025, 22022, 23023, que no existen); el
  pipeline las contó dentro del 0.91 % «con clave municipal sin clima». `conteos_capitulos`: ene–nov
  2013 tiene 5 973 826 de 5 973 845 casos en los 28 municipios «número de estado» (`i_sin2013.R`);
  los únicos municipios con casos bien asignados en 2013 son los de diciembre, que vienen del
  archivo 2014 (148 308 filas) — por eso el log de `d_conteos` da 1 488 municipios con casos en
  2013 frente a ~2 400 en los demás años.
- Consecuencia: 28 celdas municipio-año (×12 meses) con conteos de todo un estado y la exposición de
  un municipio arbitrario. Error de medida de exposición con peso enorme (Poisson pondera por el
  conteo esperado): sólo 15015 recibe 757 k casos en 2013, 09009 616 k, 11011 565 k. También
  contamina `ent^dow` y las ventanas de rezago de esos municipios. Afecta a *todas* las corridas
  (piloto, rezagos, sensibilidad A, subgrupos, marginación y cobertura por estado).
- Comparación con/sin 2013 (modelo principal completo, tres capítulos, 4 hilos; `i_sin2013.R`;
  la variante «con 2013» reproduce exactamente la tabla del pipeline, lo que de paso confirma que
  `06` es reproducible). IRR a ≥ 36 °C frente a 24–27 °C:

  | Capítulo | Variante | n | Mismo día | Acumulado 0–14 |
  |---|---|---|---|---|
  | circulatorio | con 2013 | 6 107 603 | 0.979 [0.967, 0.992] | 0.900 [0.872, 0.928] |
  | circulatorio | sin 2013 | 6 077 543 | 0.979 [0.967, 0.991] | 0.893 [0.863, 0.924] |
  | respiratorio | con 2013 | 7 138 067 | 1.026 [1.017, 1.035] | 0.775 [0.746, 0.805] |
  | respiratorio | sin 2013 | 7 096 723 | 1.027 [1.018, 1.036] | 0.775 [0.745, 0.806] |
  | traumatismos | con 2013 | 8 391 560 | 1.118 [1.108, 1.127] | 1.132 [1.110, 1.156] |
  | traumatismos | sin 2013 | 8 350 004 | 1.117 [1.107, 1.127] | 1.119 [1.096, 1.142] |

  Los puntos se mueven poco (el mayor cambio es el acumulado de traumatismos, 1.132 → 1.119) y
  ningún intervalo cambia de conclusión: las 28 celdas falsas pesan, pero su variación diaria es
  ruido respecto a la Tmax del municipio elegido y el FE absorbe el nivel. **Conclusión:** los
  resultados principales probablemente se sostienen, pero el panel contiene un año con residencia
  inventada y no se puede publicar así; hay que corregir y recorrer todo, y la cifra «119 M
  atenciones, 2012–2025» pasa a ser 2012 + 2014–2025 (o 2014–2025 si también se excluye 2012, I2).
- Propongo: (i) en `01` añadir un chequeo por año de `mean(mun_res == ent_res)` y de número de
  municipios distintos por estado, con `stop()` si un año se sale del rango de los demás; (ii)
  excluir el año calendario 2013 (o sólo el archivo 2013, conservando diciembre 2013 del archivo
  2014) hasta conseguir un archivo 2013 correcto de la DGIS; (iii) recorrer todo y actualizar README,
  especificaciones e instantánea del Drive con «antes/después» en `historico/`; (iv) añadir al
  README la cautela y al CLAUDE.md la regla («una columna con el nombre correcto no garantiza el
  contenido correcto: validar rangos por año»).

### Importantes

**I1. Municipios inexistentes y código 998 se descartan en silencio bajo la misma etiqueta.**
- Dónde: `02_panel.R:52,58` y `05_insumos_capitulos.R:36,40` (`mun_res < 999` deja pasar 998;
  `u[cve %in% m$cve]` descarta sin reportar qué claves).
- Comprobado (`b_urgencias.R`, `d_conteos.R`): 998 aparece desde 2022 (2.4–3.1 % de las filas de
  cada año; p. ej. 09998 52 931, 19998 36 551). Municipios creados después del marco del shapefile
  (HDX 2021-06, 2 457 polígonos; INEGI tenía 2 469 en 2020): 02006 San Quintín (22 379 atenciones,
  2021–2025), 02007 San Felipe, 17034–17036 (Hueyapan, Coatetelco, Xoxocotla), 07120–07124 (Chiapas),
  23011 Puerto Morelos, 04012 Dzitbalché, 04013 Seybaplaya. En conjunto ~40 k atenciones/año
  (0.5–0.6 % de 2022–2025). Sus residentes aparecen como ceros en el municipio «padre» cuyo polígono
  sí los cubre.
- Propongo: tratar 998 como 999 en `01`; mapear los municipios nuevos a su municipio de origen (tabla
  de 12 claves) y documentarlo; reportar en el log las claves descartadas con su conteo.

**I2. 2012: el 26 % sin municipio no es aleatorio; es por estado y por unidad.**
- Comprobado (`b_urgencias.R`): % de `mun_res` 999 en 2012 por `ent_res`: Colima 99.7 %, Q. Roo 99.2 %,
  Tamaulipas 98.1 %, Hidalgo 93.4 %, Chiapas 48.1 %, Nuevo León 45.5 %, Morelos 42.9 %, CDMX 37.4 %;
  75 de 633 CLUES tienen 100 % faltante (1.37 M atenciones) y 168 tienen 0 %. Por mes va de 35 % (ene)
  a 23 % (ago–nov): la cobertura mejora dentro del año.
- Por qué importa: los efectos fijos mun×año×mes absorben el nivel, así que una unidad que no
  reporta municipio todo el mes no sesga; pero una unidad que empieza a reportarlo a mitad de mes
  crea una tendencia intra-mes que se confunde con la temperatura si coincide con una ola de calor.
  No es un sesgo de selección individual (la falta es por CLUES, no por paciente), pero 2012 tiene
  cuatro estados prácticamente vacíos y una cobertura que crece durante el año.
- Propongo: sensibilidad excluyendo 2012 (junto con la exclusión de 2013 queda 2014–2025) y decir en
  el README que 2012 cubre ~74 % de las atenciones y cuatro estados casi nulos.

**I3. Cambio de fuente en 2024–2025 (IMSS-Bienestar) con caídas de volumen grandes por estado.**
- Comprobado: `cobertura_institucion_anio.csv`: `IMB` = 0 % hasta 2023, 67.5 % en 2024 y 66.8 % en
  2025. `cobertura_estado_anio.csv`: volumen 2024 relativo a 2019: BS 0.60, SP 0.62, HG 0.70, MN 0.75,
  ZS 0.79, MC 0.77; CM 1.57, CS 1.52, YN 1.40. El README dice «desde 2023»; en estos datos la
  recodificación es en 2024.
- Por qué importa: cambios de nivel por estado-año los absorbe el FE; cambios de cobertura *dentro*
  del mes (transferencias de unidades) no. Además, el denominador implícito (población que acude a
  esas unidades) cambia de composición.
- Propongo: la sensibilidad 2012(14)–2022 que la propia especificación C anticipa; corregir «2023».

**I4. Inferencia: sólo se agrupa por municipio; la sobredispersión existe y hay correlación espacial
y temporal común.**
- Comprobado en submuestra (`e_modelo.R`, 2019, 2 457 mun × 365 d): dispersión de Pearson χ²/gl =
  1.02 (ojo) y 1.08 (circulatorio) *condicional a los FE*, pero var/media marginal = 3.5 en
  circulatorio; EE «iid» < «hetero» < «cluster» (circulatorio, v0 ≥ 36: 0.0183 / 0.0200 / 0.0219).
  `fenegbin` da el mismo punto (0.994 vs 0.993) con EE iguales. Comparación de agrupamientos en
  2018–2019 (`g_cluster.R`, mismo modelo, sólo cambia `vcov`; EE del acumulado ≥ 36):

  | Capítulo (2018–19) | ~cve (actual) | ~ent | ~cve + fecha | ~ent + fecha |
  |---|---|---|---|---|
  | circulatorio (acum. 0.875) | 0.046 → [0.799, 0.958] | 0.059 → [0.780, 0.982] | 0.054 → [0.787, 0.973] | 0.064 → [0.772, 0.993] |
  | traumatismos (acum. 1.157) | 0.023 → [1.107, 1.209] | 0.023 → [1.105, 1.211] | 0.032 → [1.087, 1.232] | 0.032 → [1.087, 1.232] |

  Los EE crecen 20–40 % con agrupamiento por estado o bidireccional (las variantes con `fecha` dan
  el aviso «VCOV not positive definite, fixed»). En los capítulos grandes la conclusión no cambia;
  en los chicos (ojo, oído, sangre, osteomuscular, digestivo, cuyos IC ya rozan 1) sí puede cambiar.
- Valoración: el estimador Poisson-FE es consistente bajo sobredispersión y el sándwich por
  municipio es la elección estándar; NB con efectos fijos no mejora (Allison & Waterman 2002;
  Wooldridge 1999). Lo que un revisor pedirá es (a) decirlo explícitamente, (b) una sensibilidad con
  agrupamiento por estado o bidireccional (municipio + fecha), porque la Tmax y los choques de
  demanda (epidemias, festivos, paros) están correlacionados entre municipios el mismo día.
- Propongo: añadir `vcov = ~cve + fecha` (o `~ent`) como sensibilidad en `06` (es un `vcov()`
  post-estimación, no requiere reestimar).

**I5. Identificación del bin ≥ 36 °C: concentrada geográfica y estacionalmente.**
- Comprobado (`c_clima.R`, `f_fe_removidos.R`): ≥ 36 °C es el 4.17 % de los municipio-días y el
  5.46 % de los casos; 588 de 2 457 municipios nunca lo alcanzan (170 nunca bajan de 12 °C). Los días
  ≥ 36 vienen de Sonora 16 %, Nuevo León 12 %, Veracruz 11 %, Yucatán 9 %, Tamaulipas 8 %, Oaxaca 6 %,
  Coahuila 6 %; 75 % entre mayo y agosto.
- Por qué importa: el IRR de ≥ 36 es un efecto «dentro de municipio-mes» en los municipios cálidos;
  no es generalizable a los templados, y los terciles de marginación (espec. D) comparan poblaciones
  con distribuciones de exposición muy distintas (la propia espec. lo advierte). Sugerencia: reportar
  también la distribución de días ≥ 36 por tercil y el bin 33–36, y considerar percentiles
  municipales de Tmax como especificación alternativa.

**I6. Las ventanas de rezago no cruzan bien los efectos fijos mensuales (ya anticipado en la
especificación) y el perfil «1–3 / 4–7 / 8–14» se interpreta como por día.**
- Comprobado: el acumulado se calcula como β₀ + 3β₁₋₃ + 4β₄₋₇ + 7β₈₋₁₄ (`06:56-58`; recomputado
  desde la tabla con error máximo 8e-16) y su EE usa `V[nm, nm]` completa (cociente EE
  completa/EE diagonal entre 0.75 y 1.18 según capítulo, así que la covarianza importa). El perfil
  por ventana es el coeficiente por día (`06:53-54`), coherente con la etiqueta del eje en `07:54`.
- Lo que un revisor objetará: (a) un regresor «número de días de la ventana en el bin» impone el
  mismo efecto en cada día de la ventana (restricción escalonada); frente a un DLNM con splines no
  es peor en sí, pero hay que justificarlo; (b) con FE mun×año×mes, la ventana 8–14 compite con la
  variación intra-mes y el «acumulado» respiratorio de 0.775 (v0 1.026, v8–14 0.980) puede ser
  desplazamiento + estacionalidad residual no absorbida; (c) el acumulado como suma de log-IRR
  supone líneas de base iguales en los 15 días. Nada de esto es error; es lo que hay que discutir.

**I7. Reproducibilidad del README incompleta.**
- El bloque «Reproducir» no menciona `08`–`12`, las variables `FE_SPEC`, `CONTEOS`, `MARG`, ni los
  paquetes `ggplot2`, `foreign`, `readxl`. `02` no recibe periodo (está fijo a 2012–2025), así que
  `*_2012_2022.*` no se regeneran con el código actual. `10_figuras_sensibilidad.R:19` lee
  `rezagos_fe-anio_semana_<periodo>.csv`, que aún no existe (la corrida estaba en curso); fallará
  hasta que termine. Las figuras `sensibilidad_fe_*` y `subgrupos_*` no están en `resultados/figuras/`.
  El clima 2011–2022 viene de los `.rds` de Diana (raster::extract), no regenerables con `00`
  (validado sólo contra 2022: cor = 1, dif. máx. 0.026 °C, confirmado en `c_clima.R`).
- `ESPECIFICACION_sensibilidad_subgrupos.md` sección D habla de «diferencia alto − bajo con EE
  √(EE₁²+EE₃²)»: `12_figura_marginacion.R:19-21` lo implementa así. `11_marginacion_terciles.R:18`
  invierte el signo del IM 2020 (método DP2: IM alto = menos marginación), con `stopifnot` contra
  `GM_2020`; correcto.

### Menores

**M1. Conteo de líneas descartadas en `01` (`01:27,37`).** `wc -l` cuenta saltos de línea; 2015 y 2021
no terminan en `\n`, así que 2015 descarta en realidad 72 (no 71: 51 con NF≠26 + 67 no ASCII, unión
72) y 2021 reporta «−1» en el log. 2016, 2017 y 2019 descartan 3 líneas cada uno (pie
`(n row(s) affected)` y líneas vacías; no es corrupción). El README dice «71 y 20».

**M2. `01` descarta líneas con cualquier byte fuera de ASCII imprimible (`01:26`).** En estos años
no hay campos de texto libre y las líneas afectadas son basura (comprobado en 2015), pero es una
regla frágil para años futuros con nombres o acentos; mejor filtrar por NF y validar campos.

**M3. Filas con fecha de ingreso en el año anterior.** 2012–2015: 141–171 k por archivo, todas de
diciembre del año previo (comprobado para 2013→2012: 100 % diciembre), consistente con archivos por
fecha de alta. El filtro por `fecha` las coloca en el año correcto. Riesgo no comprobable sin ID:
que la misma atención aparezca en dos archivos (no hay identificador estable; el README debería
decirlo). 2017 contiene fechas absurdas (1931, 2520; ~1 k filas) que el filtro elimina.

**M4. Chequeo vacuo en `05:47`.** `cods` se construye con `unique(u$cie3)`, así que
`!anyDuplicated(cie3)` nunca falla; no detecta un código que cayera en dos rangos. Los rangos no se
solapan (llaves 100–299, 450–489, 500–590, …, 1900–2098), T98 entra, D00–D48 y C quedan fuera,
H59/H60 separan bien (verificado en `b_urgencias.R`: 1 691 códigos, todos `^[A-Z][0-9][0-9]$`, 0 sin
llave). Sustituir por un chequeo de solapes entre `k1,k2` de `capitulos`.

**M5. `semana = isoweek(fecha)` en la sensibilidad A (`06:31`).** `isoweek(2012-12-31) = 1`: el
29–31 de diciembre cae en la semana 1 del año siguiente con `cve^anio` del año en curso. Efecto
pequeño; alternativa `week()` o `yday %/% 7`.

**M6. README «2,457 municipios (HDX 2021)».** INEGI 2020 tenía 2 469; el shapefile omite los creados
2016–2021 (I1). Decirlo.

**M7. `09_cobertura_clues.R`** usa todas las filas del parquet (incluidas las sin residencia válida);
coherente con «cobertura de la fuente», pero el README debería aclararlo. `idx_2019` para estados
sin 2019 daría `Inf`; no ocurre.

**M8. Logs.** No hay log de `11`; `06_modelo_rezagos_fe-anio_semana` se está sobrescribiendo en la
corrida actual. `04` da *warnings* de `mbcsToSbcs` por el guion largo en el PDF (sólo cosmético).

## Cifras verificadas

| Cifra reportada | Fuente | Valor encontrado | ¿Coincide? |
|---|---|---|---|
| 119 M atenciones 2012–2025 | README | 119 266 584 (`01_leer_urgencias_2012_2025.log`) | Sí |
| 2 457 municipios | README/espec. | 2 457 en dbf, en `.rds` y en `clima_ventanas` | Sí |
| Piloto traumatismos mismo día 1.138 [1.128, 1.147] | README | 1.138 [1.128, 1.147] (`piloto_coeficientes_2012_2025.csv`) | Sí |
| Piloto traumatismos acum. 0–3 1.169 [1.156, 1.181] | README | 1.169 [1.156, 1.181] | Sí |
| Piloto genitourinario 1.085 / 1.112 | README | 1.085 [1.075, 1.095] / 1.112 [1.096, 1.128] | Sí |
| Piloto circulatorio 0.964 / 0.927 | README | 0.964 [0.953, 0.975] / 0.927 [0.911, 0.943] | Sí |
| «Con 2012–2022 prácticamente iguales» | README | 0.957/0.919, 1.081/1.112, 1.137/1.170 (`*_2012_2022.csv`) | Sí |
| Rezagos: 16 filas de la tabla (mismo día y acum. 0–14, ≥ 36) | README | todas iguales a `rezagos_2012_2025.csv` redondeadas a 3 decimales (`a_cifras.R`) | Sí (16/16) |
| `rezagos_2012_2025_bin36.csv` vs tabla completa | Drive | dif. máx. 0 | Sí |
| Total n = 10 126 338, eliminadas 2 438 760 | log 06 / resumen | suma = 12 565 098 = 2 457 × 5 114 | Sí |
| FE eliminados = celdas mun-año-mes sin casos | log 06 | iguales en los 16 modelos (0 singletons) (`f_fe_removidos.R`) | Sí |
| 4 31-dic imputados; 5 479 días | log 05 | 2012, 2016, 2020, 2024; 2011-01-01..2025-12-31 = 5 479 | Sí |
| V4.0 vs V4R1 2022: cor = 1, dif. máx. 0.026 °C | README | cor = 1.000, dif. máx. 0.0260, media 9e-6 | Sí |
| 2015 y 2018: 71 y 20 líneas corruptas | README | 72 y 20 (y 3 en 2016, 2017, 2019) | No (menor) |
| IMSS-Bienestar «desde 2023» | README/espec. C | `IMB` 0 % en 2023, 67.5 % en 2024 | No (es 2024) |
| «0.91 % con clave municipal sin clima» | log 02 | cierto, pero 1.04 M de ellas son 2013 con claves inexistentes (B1) | Engañoso |
| Subgrupos E86 2.061 [1.863, 2.279]; I21 0.974; N17 0.943 | log 06 subgrupos | iguales en `rezagos_subgrupos_2012_2025.csv` | Sí |
| Sensibilidad A (en curso): circulatorio 0.890, digestivo 0.964 | log parcial | digestivo cambia de 1.027 a 0.964 (signo contrario) | A reportar como fragilidad |

## Lo que NO pude verificar y por qué

- **Duplicados de atenciones entre archivos anuales**: la tabla compacta no conserva `ID`/`FOLIO` y
  los crudos no tienen un identificador estable entre años.
- **Si existe un archivo 2013 correcto en la DGIS** (sin acceso web desde esta sesión). El de aquí
  es de jul-2023; el script legacy de Diana (`5_limpieza…:67`) tampoco lo detectó.
- **Resultados de la sensibilidad A y de los terciles**: estaban corriendo; sólo vi los logs
  parciales. Nota: todo lo que se está corriendo hereda el problema B1.
- **El impacto completo de B1 sobre los 16 modelos**: sólo recorrí tres capítulos con y sin 2013
  (B1); el resto hay que recorrerlo.
- **Daymet como exposición**: no comparé contra estaciones; el promedio de polígono para
  municipios grandes y heterogéneos (Ensenada, Mexicali, los de Chihuahua/Sonora) diluye los
  extremos, y Tmax sin humedad no capta la carga térmica del Golfo/Yucatán (temperatura aparente o
  índice de calor serían la sensibilidad natural; Daymet trae `vp`).
- **Offset de población**: no hace falta con FE mun×año×mes (cualquier población constante dentro
  del mes queda absorbida exactamente); sí importaría con la especificación A (`cve^anio` también lo
  absorbe) — no es un problema, pero conviene decirlo en el README.
- **Exposición residencia vs lugar de atención**: correcto usar residencia; no pude medir cuánto
  cruza de municipio la atención (haría falta cruzar CLUES con su municipio; el catálogo está en
  `Datos/CLUES/`). Sería una sensibilidad útil (restringir a atenciones en el mismo municipio).

## Notas metodológicas adicionales (para el manuscrito, no son errores)

- Bins fijos de 3 °C con referencia 24–27 °C: razonable y comparable con Burke et al.; un revisor
  pedirá además percentiles municipales (el 24–27 es «frío» en Mexicali y «caliente» en Toluca) y
  una curva continua (spline) como sensibilidad.
- 16 desenlaces: la especificación ya dice cómo se tratan; conviene una corrección (Holm o BH) en la
  tabla principal o al menos reportar p-valores.
- Festivos: no hay FE de festivos; en días de asueto la demanda de urgencias cambia; el FE ent×dow
  no lo capta. Añadir un indicador de festivo federal es barato.
- Precipitación: sólo mismo día y en 4 bins; es un control, está bien.
- Cobertura: los datos son casi 100 % SSA (luego IMB); el denominador es población sin seguridad
  social; decirlo en limitaciones.
