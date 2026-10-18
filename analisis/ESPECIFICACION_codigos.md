# Especificación comprometida H: barrido por código CIE-10 de 3 caracteres

Escrita el 2026-10-17, **antes de correr ningún modelo de esta etapa**. Es un nivel
**exploratorio** por debajo de los capítulos (`ESPECIFICACION_capitulos_rezagos.md`, que sigue
siendo el análisis principal). Pregunta: ¿qué diagnósticos concretos se registran de más o de
menos en urgencias según la temperatura, y cambia eso con la marginación?

## H1. Desenlaces

Códigos CIE-10 de 3 caracteres con **≥ 100,000 atenciones con municipio de residencia válido en
2012–2025 (sin 2013)**. Con ese umbral son 164 códigos que cubren el 85.7 % de las atenciones
(contado el 2026-10-17 antes de escribir esto). Por debajo del umbral `fepois` vacía casi todo
el panel y los intervalos no son interpretables. No se añaden ni quitan códigos después de ver
resultados.

Los códigos del capítulo Z (factores que influyen en el estado de salud: Z34 control de embarazo
normal, Z35, Z71 consejería, etc.; 11 con ≥ 100,000) se corren igual y se reportan aparte como
**controles negativos**: no deberían responder a la temperatura salvo por la decisión de acudir
o no a la unidad. Su efecto estima el «efecto de ir a la clínica» que contamina al resto; se
reporta como referencia, no se resta en el análisis principal.

## H2. Modelo

Idéntico al principal: `fepois(casos ~ días-en-bin por ventana (0, 1–3, 4–7, 8–14) + i(bp) |
cve^anio^mes + ent^dow)`, errores agrupados por municipio, panel con ceros explícitos,
Tmax en bins de 3 °C con referencia [24, 27). Un ajuste por código (`06_modelo_rezagos.R` con
`CONTEOS=codigos`). Insumo: `21_insumos_codigos.R` → `conteos_codigos_2012_2025.parquet`.

## H3. Contrastes y pruebas múltiples

Dos contrastes por código, fijados aquí: **acumulado 0–14 d en [36, ∞)** y **acumulado 0–14 d
en (−∞, 12)**, ambos como log-IRR con su EE (agrupado por municipio).

- **FDR**: Benjamini–Hochberg al 5 % **dentro de cada contraste**, sobre los 164 códigos
  (los Z incluidos en la corrección, para no favorecerla). Se reporta el q-valor.
- **Contracción empírico-bayesiana**: modelo normal-normal por capítulo (letra del código):
  β_c ~ N(μ_cap, τ²_cap), β̂_c | β_c ~ N(β_c, se_c²); τ² por DerSimonian–Laird (momentos) con
  piso 0; media posterior β̃_c = (β̂_c/se_c² + μ_cap/τ²_cap)/(1/se_c² + 1/τ²_cap). Capítulos con
  < 3 códigos se contraen hacia la media global. Se reportan β̂ y β̃; el **ranking y la figura
  usan β̃**, la prueba FDR usa β̂/se (no se prueba sobre el estimador contraído).
- No hay `ashr` en el entorno; si se instala después, se reporta como comparación, no se cambia
  lo anterior.

## H4. Marginación (paso 2, condicionado)

Sólo para los códigos con q < 0.05 en el contraste de calor (cualquier signo), excluidos los Z:
- D: terciles de marginación CONAPO 2020 (`MARG=1,2,3`), cociente M3/M1 del acumulado 0–14 a ≥ 36 °C.
- E: a clima de base constante (`CLIMA=k, MARG=j`, 3 × 3), como en la especificación E.
Si pasan más de 50 códigos, se corre D para todos y E sólo para los 20 de mayor |β̃| de calor.
Pruebas múltiples en este paso: BH al 5 % sobre los cocientes M3/M1.

## H5. Interpretación comprometida de antemano

- Un código es el **diagnóstico de egreso registrado**, no un síntoma presente. Hay sustitución
  entre códigos vecinos (E86 / R50 / R51 / T67) y los efectos son parcialmente composicionales:
  cada atención lleva un solo código. Los resultados se leen por grupos de códigos vecinos.
- Hipótesis a priori (para juzgar el barrido, no para seleccionar): suben con calor A09 (diarrea
  infecciosa), N39 (infección urinaria), T63 (picadura de alacrán), E86, L (piel); bajan J00/J02/J06
  (respiratorio alto); I10 (hipertensión) baja con calor como el capítulo circulatorio.
- Lo que no se predijo y pasa el FDR se reporta como hallazgo exploratorio, a replicar.

## H6. Piloto

Antes del barrido completo: A09, N39, T63, J02, R50, Z34 (6 códigos) para verificar la forma de
la salida y los tiempos. El piloto no cambia H1–H5.

## H7. Salidas

`resultados/tablas/rezagos_codigos_2012_2025.csv` (todos los coeficientes), `_resumen.csv`,
`codigos_fdr_2012_2025.csv` (código, capítulo, casos, β̂, se, q, β̃ por contraste),
`datos/derivados/codigos_incluidos.csv` (lista comprometida con casos). Figura 9: *heatmap* código ×
bin del log-IRR contraído (acumulado 0–14), ordenado por capítulo, marcando q < 0.05.
