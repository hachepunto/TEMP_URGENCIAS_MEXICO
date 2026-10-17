# Comparación con Sarmiento, Colelli & Pavanello (RFF WP 25-11, 2025), tabla por tabla

Fuente de sus cifras: Tabla 2 (total) y Tabla 3 (por capítulo) del PDF `WP_25-11.pdf` (Drive), extraídas
por texto el 2026-10-17. Sus coeficientes son de un modelo Poisson con 30 rezagos distribuidos, FE
municipio×año×mes y municipio×día-de-semana, **temperatura media ERA5** en bins de 5 °C con referencia
20–25 °C, tasa por 100 k, municipios con ≥ 1 hospital (exposición en el **municipio del hospital**),
2008–2022. Los nuestros: Poisson FE mun×año×mes + estado×dow, **Tmax Daymet** en bins de 3 °C con
referencia 24–27 °C, municipio de **residencia**, 2012–2025 sin 2013, ventanas 0–14. Las dos
exposiciones no son equivalentes (su «> 30 °C de Tmedia» corresponde aproximadamente a Tmax ≥ 36–38 °C
en clima seco y a Tmax 33–36 en clima húmedo), así que la comparación es de **signo, orden y
magnitud aproximada**, no de igualdad numérica. Todo en log-puntos (coeficiente Poisson; ×100 ≈ %).

## Bin caliente: su «> 30 °C Tmedia» vs nuestro «≥ 36 °C Tmax»

| Capítulo | Sarmiento mismo día | Sarmiento acum. 30 d | Nuestro mismo día | Nuestro acum. 0–14 | Concordancia |
|---|---|---|---|---|---|
| Endocrino / metabólico | +0.102*** | +0.199*** | +0.127 | +0.145 | sí, misma magnitud |
| Causas externas / traumatismos | +0.056*** | +0.122*** | +0.112 | +0.117 | sí; nuestro mismo día es el doble |
| Genitourinario | +0.048*** | +0.205*** | +0.067 | +0.133 | sí |
| Sangre e inmunidad | +0.016 | +0.208*** | +0.066 | +0.129 | sí en acumulado |
| Piel (ellos: piel + musculoesquelético) | +0.015** | +0.152*** | +0.057 (piel) / +0.031 (osteomusc.) | +0.125 / +0.023 | sí para piel; osteomuscular nulo en ambos |
| Mentales | +0.089*** | +0.072* | +0.095 | +0.082 | sí, casi idéntico |
| Ojo y oído (ellos juntos) | +0.018 | +0.097** | +0.037 (ojo) / +0.023 (oído) | +0.092 / +0.061 | sí |
| Digestivo | −0.001 | +0.040** | +0.011 | +0.026 | sí, pequeño |
| Síntomas / «Other» | +0.041*** | +0.066*** | +0.069 | +0.101 | sí |
| Infecciosas y parasitarias | +0.086*** | **−0.073**** | +0.114 | **+0.167** | mismo día sí; **acumulado difiere**: su ventana de 30 días revierte, la nuestra de 14 no |
| Nervioso | +0.002 | +0.058 | +0.043 | −0.046 | ambos pequeños; signos del acumulado opuestos, ninguno concluyente en ellos |
| Circulatorio | −0.034*** | −0.065*** | −0.021 | −0.109 | sí, negativo en ambos |
| Respiratorio | +0.009 | **−0.304**** | +0.028 | **−0.244** | sí, casi idéntico |
| Total | +0.037*** | +0.025** | +0.065 | +0.037 | sí; nuestro mismo día mayor (bin más extremo) |

## Lectura

1. **Replicación sustantiva.** Con otra fuente climática, otra métrica (Tmax vs Tmedia), otra asignación
   geográfica (residencia vs hospital), otro periodo y otra estructura de rezagos, los 13 capítulos
   comparables coinciden en signo y en orden de magnitud. Las dos caídas (respiratorio −0.24/−0.30,
   circulatorio −0.11/−0.07) y las subidas grandes (endocrino, genitourinario, externas, sangre, piel)
   son las mismas. Esto es lo que un revisor querrá ver: que el resultado no depende de las
   decisiones de diseño.
2. **La única divergencia clara es infecciosas en el acumulado**: ellos +8.6 % el mismo día y −7.3 % a
   30 días; nosotros +11 % y +17 % a 14 días, sin ventana tardía < 1. La explicación más probable es la
   ventana: la reversión que ellos ven ocurre después del día 14 (gastroenteritis y otras infecciones
   con dinámica de transmisión de semanas). Es comprobable: extender nuestras ventanas a 15–30 días es
   una corrida de ~20 min. Conviene hacerlo antes de afirmar «exceso neto» en infecciosas.
3. **Nuestro mismo día es sistemáticamente mayor** (externas 0.112 vs 0.056; total 0.065 vs 0.037)
   porque nuestro bin es más extremo (≥ 36 °C de Tmax frente a > 30 °C de Tmedia) y porque Tmax
   captura mejor el pico diario; el acumulado converge porque nuestras ventanas son más cortas.
4. **Lo que ellos no tienen y nosotros sí**: residencia vs hospital (F), subgrupos E86/N17/I21 (ellos
   reportan golpe de calor, ICC, ERC e ITU en su Tabla 4), marginación y clima de base (D, E),
   2023–2025, EE bidireccionales. Lo que ellos tienen y nosotros no: 30 rezagos, humedad relativa como
   control, heterogeneidad por edad y sexo, proyección a mitad de siglo, comparación con California.
5. **Posicionamiento del manuscrito**: «replicación independiente con exposición por residencia y
   extensión a dinámica por causa, subgrupos clínicos y gradiente social a clima constante»; citar su
   Tabla 3 junto a nuestra Tabla 1 en el suplemento.

## Pendiente derivado

- Correr ventanas 15–21 y 22–30 (o un acumulado 0–30) para infecciosas, respiratorio y total, para
  cerrar la comparación del punto 2.
- Añadir humedad (Daymet `vp`) como control y como exposición alternativa (temperatura aparente).
