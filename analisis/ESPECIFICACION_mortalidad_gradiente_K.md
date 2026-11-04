# Especificación comprometida K: ¿qué carga el gradiente inverso de mortalidad por calor? Ámbito urbano/rural, componentes de la marginación y asistencia médica

Escrita el 2026-11-04, **antes de correr nada de esta etapa** y antes de tabular las variables nuevas de los microdatos (`area_ur`, `asist_medi` a nivel individual) o los componentes del IMM. Motivación: G (ii)–(iii) dio el exceso de mortalidad a ≥ 36 °C **menor** en el tercil más marginado (todas M3/M1 0.921 [0.87, 0.98]; circulatorio 0.84), y J descartó la estructura de edad (el gradiente está en ≥ 65: 0.861) y la calidad visible del registro a nivel municipal (en municipios de buen registro: 0.907). Quedaron sin probar: urbanidad (isla de calor, aislamiento), vivienda, aclimatación/ocupación y la precisión de causa y fecha en muertes sin asistencia médica.

Modelo en todo: el de G y J (Poisson FE `cve^anio^mes + ent^dow`, bins de Tmax de 3 °C, ref. 24–27, ventanas 0, 1–3, 4–7, 8–14, acumulado 0–14 a ≥ 36 °C, EE por municipio, 2012–2024). Cocientes T3/T1 (o M3/M1) con EE por suma de varianzas, como en `28` y `29`. Referencia para «más cerca de 1»: el cociente combinado de G (ii), todas 0.921.

## K-a. Ámbito de residencia, urbano o rural (individual)

Variable `area_ur` de cada defunción (INEGI: 1 urbana = localidad de residencia ≥ 2,500 hab., 2 rural; otros valores = no especificado, fuera sólo de estos desenlaces). Desenlaces (4): todas las causas y circulatorio, cada uno urbano y rural.

Por qué: Daymet promedia la Tmax sobre el polígono municipal (1 km); en municipios urbanos la exposición real de la población es mayor que ese promedio (isla de calor, más fuerte de noche), y M1 es mayoritariamente urbano. Si el mismo bin de Daymet implica más calor real en ciudad, el efecto «por bin» sería mayor en M1 sin que la marginación proteja. Lo mismo predice el aislamiento de adultos mayores urbanos.

1. Descriptivo: % de defunciones urbanas por tercil de marginación.
2. Modelo nacional y por tercil (`MARG=1,2,3`) para los 4 desenlaces; cociente M3/M1 dentro de cada ámbito; BH sobre los 4 cocientes.

Criterio: el ámbito **explica** el gradiente si (i) a nivel nacional el efecto en todas las causas es mayor en urbano que en rural, y (ii) dentro de **cada** ámbito el cociente M3/M1 de todas las causas tiene IC 95 % que incluye 1 y estimación puntual más cerca de 1 que 0.921. **No lo explica** si en algún ámbito con IC informativo (ancho del IC del log-cociente < 0.4) el cociente sigue < 1 con IC que excluye 1. Cualquier otro patrón se reporta como **indeterminado** (p. ej. IC demasiado anchos en M3 urbano, que se espera con pocas defunciones).

## K-b. Componentes del índice de marginación (municipal)

Terciles, por número de municipios entre los 2,457 del panel (como en `11`), de cinco indicadores del IMM 2020; T3 = mayor porcentaje (más carencia):
- `PL.5000` % de población en localidades < 5,000 hab. (ruralidad);
- `VHAC` % de viviendas con hacinamiento;
- `OVPT` % de ocupantes en viviendas con piso de tierra;
- `OVSEE` % de ocupantes en viviendas sin energía eléctrica (sin ventilador ni aire acondicionado posibles);
- `PO2SM` % de población ocupada con ingreso ≤ 2 salarios mínimos.

1. Descriptivo: correlaciones de Spearman entre los cinco indicadores y el IM 2020.
2. Modelo por tercil de cada indicador (`MUNICIPIOS=<lista>`, 15 corridas) para todas y circulatorio; cociente T3/T1; BH sobre los 10 cocientes.

Lectura fijada aquí (descriptiva: los indicadores están correlacionados y no se separan causalmente):
- **ruralidad**, si `PL.5000` da T3/T1 de todas < 1 con q < 0.05 y ninguno de los tres de vivienda (`VHAC`, `OVPT`, `OVSEE`) lo da;
- **vivienda**, si al menos uno de los tres de vivienda lo da y `PL.5000` no;
- **no separable**, si lo dan `PL.5000` y al menos uno de vivienda, o ninguno.
`PO2SM` se reporta sin entrar en la regla. Una predicción que se declara de antemano: si `OVSEE` T3/T1 sale < 1, contradice la hipótesis de enfriamiento (sin electricidad debería aumentar el efecto, no reducirlo).

## K-c. Asistencia médica antes de morir (individual)

Variable `asist_medi` de cada defunción (1 con asistencia, 2 sin asistencia; otros valores fuera de estos desenlaces). Desenlaces (4): todas y circulatorio, con y sin asistencia.

Por qué: en las muertes sin asistencia médica la causa (certificada sin atención) y probablemente la fecha son menos precisas; M3 tiene 25.9 % sin asistencia frente a 11.4 % en M1 (J-b). El error no diferencial en la causa o en el día atenúa hacia 1 el efecto en M3. J-b sólo midió la calidad visible por municipio; esto la mide por defunción.

1. Modelo nacional y por tercil para los 4 desenlaces; cociente M3/M1 dentro de cada estrato; BH sobre los 4.

Criterio: la imprecisión de las muertes sin asistencia **explica** el gradiente si, **con asistencia**, el cociente M3/M1 de todas incluye 1 y su estimación puntual está más cerca de 1 que 0.921. **No lo explica** si con asistencia el cociente sigue < 1 con IC que excluye 1. Límite declarado: la asistencia médica no es aleatoria (selección por acceso y gravedad); el estrato «con asistencia» de M3 no es comparable a la población de M3, sólo sirve para descartar o no el mecanismo de imprecisión.

## Lo que K no prueba

Aclimatación con umbrales relativos (bins definidos por percentiles locales de Tmax) y Tmin (noches cálidas) requieren insumos de clima nuevos; se dejan para una etapa posterior si K no resuelve el gradiente. La ocupación (trabajo al aire libre) predice un efecto **mayor** en M3, el sentido contrario al observado, y no se prueba.

## Implementación

- `19_leer_defunciones.R` conserva además `area_ur` (antes de correr se tabula sólo su codificación por año, sin cruzarla con temperatura).
- `20c_conteos_defunciones_k.R` → `conteos_defunciones_k_2012_2025.parquet` (8 desenlaces: `todas|circulatorio` × `urbano|rural|conasist|sinasist`) y listas de municipios por tercil de cada indicador (`datos/derivados/comp_<indicador>_t<k>.txt`).
- `06_modelo_rezagos.R`: `CONTEOS=defunciones_k` (mismo recorte de fechas que defunciones).
- `31_mortalidad_gradiente_k.R`: descriptivos, cocientes, criterios → `mortalidad_gradiente_k_2012_2025.csv`.
- `32_figura_mortalidad_marginacion.R`: figura del gradiente (G ii–iii, J y K), sólo dibuja desde las tablas.
