# Especificación comprometida J: ¿por qué la mortalidad por calor es menor en municipios marginados?

Escrita el 2026-10-18, **antes de correr nada de esta etapa** y después de ver el resultado que la
motiva: G (ii)–(iii) dio el exceso de mortalidad a ≥ 36 °C **menor** en el tercil más marginado
(todas M3/M1 0.92 [0.87, 0.98]; circulatorio 0.84 [0.76, 0.93]; en el estrato de clima cálido 0.87 y
0.79), contrario a la hipótesis comprometida. Se ponen a prueba dos explicaciones que se pueden
distinguir con los microdatos de defunciones; una tercera (aclimatación u ocupación) no se puede
separar con estos datos y queda como residual.

Modelo en todo: el de G (Poisson FE `cve^anio^mes + ent^dow`, bins de Tmax de 3 °C, ref. 24–27,
ventanas 0, 1–3, 4–7, 8–14, acumulado 0–14 a ≥ 36 °C, EE por municipio, 2012–2024). Cociente M3/M1 con
EE por suma de varianzas, como en `28_defunciones_marginacion.R`.

## J-a. Estructura de edad

Edad al morir del campo `edad` (INEGI: 4xxx = años cumplidos; < 4000 = menores de un año; 4998 = no
especificada, se excluye sólo de los desenlaces por edad). Desenlaces (4): todas las causas y
circulatorio, cada uno en **< 65 años** y **≥ 65 años**.

1. Descriptivo: proporción de defunciones ≥ 65 por tercil de marginación.
2. Modelo nacional y por tercil (`MARG=1,2,3`) para los 4 desenlaces; cociente M3/M1 dentro de cada
   grupo de edad. BH sobre los 4 cocientes.

Criterio fijado aquí: la edad **explica** el gradiente si (i) el efecto del calor es mayor en ≥ 65 que
en < 65 a nivel nacional, y (ii) dentro de ≥ 65 el cociente M3/M1 de todas las causas tiene un IC 95 %
que incluye 1 y una estimación puntual más cercana a 1 que la combinada (0.921). Si el cociente dentro
de ≥ 65 sigue < 1 con IC que excluye 1, la edad no lo explica.

## J-b. Calidad del registro

Indicadores por municipio de residencia (2012–2024, todas las defunciones con residencia válida,
incluidas las de fecha incompleta):
- % con fecha de ocurrencia incompleta (día o mes no especificados: esas defunciones no entran al panel);
- % registradas en un año posterior al de ocurrencia (registro tardío);
- % sin asistencia médica (`asist_medi == 2`);
- % con edad no especificada.

1. Descriptivo: los cuatro indicadores por tercil de marginación (mediana municipal y agregado).
2. Sensibilidad: se repite el contraste M3/M1 de G (ii) (todas y circulatorio) **sólo con municipios
   de registro de buena calidad**, definidos aquí como los que están en o por debajo del percentil 75
   nacional (entre municipios con ≥ 100 defunciones en el periodo) **tanto** en % de fecha incompleta
   **como** en % de registro tardío. Municipios con < 100 defunciones quedan fuera de esta
   sensibilidad.

Criterio: la calidad **explica** el gradiente si (i) M3 tiene peores indicadores que M1, y (ii) en la
submuestra de buena calidad el cociente M3/M1 de todas las causas se acerca a 1 (IC que incluye 1).
Si el cociente se mantiene igual o se aleja de 1, la calidad del registro no lo explica.

Límite que se declara de antemano: un error en la fecha de ocurrencia que no queda marcado como «no
especificado» (fecha equivocada pero completa) no es observable; J-b sólo mide la calidad visible.

## Implementación

- `19_leer_defunciones.R` conserva además `edad_anios`, `anio_regis`, `asist_medi` y escribe
  `datos/derivados/calidad_defunciones_municipio.csv` (indicadores por municipio, incluidas las
  defunciones con fecha incompleta).
- `20b_conteos_defunciones_edad.R` → `conteos_defunciones_edad_2012_2025.parquet` (4 desenlaces).
- `06_modelo_rezagos.R`: `CONTEOS=defunciones_edad` (mismo recorte que defunciones) y
  `MUNICIPIOS=<archivo>` (lista de `cve` a conservar; sufijo `_mun-<nombre>`).
- `29_mortalidad_edad_calidad.R`: descriptivos, cocientes y tabla `mortalidad_edad_calidad_2012_2025.csv`.
