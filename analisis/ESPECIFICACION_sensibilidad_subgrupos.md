# Especificación comprometida: sensibilidad de efectos fijos, subgrupos clínicos, cobertura

Escrita el 2026-10-17, **antes de correr ningún modelo de esta etapa**. Parte del modelo de
rezagos (`ESPECIFICACION_capitulos_rezagos.md`), que sigue siendo el principal.

## A. Sensibilidad: efectos fijos menos restrictivos

Mismo modelo de rezagos 0–14, mismos 16 desenlaces, cambiando sólo los efectos fijos:

- Principal (ya corrido): `cve^anio^mes + ent^dow`.
- Sensibilidad A: `cve^anio + ent^semana_iso + ent^dow`. Municipio × año absorbe nivel y
  tendencia anual; estado × semana del año absorbe la estacionalidad común del estado, pero deja
  que un municipio tenga semanas más calientes de lo normal *respecto a su año*, no sólo respecto
  a su mes. Así se recupera parte de la variación de olas de calor de varias semanas y del frío
  con rezago.

Qué se espera: efectos del calor de magnitud parecida o mayor (hay más variación identificante);
en el lado frío, intervalos más estrechos y posiblemente efectos > 1 en respiratorio e
infecciosas (el signo contrario al principal, que ahí no era interpretable). Si el calor cambia
de signo en algún capítulo, se reporta como fragilidad, no se elige la versión conveniente.

## B. Subgrupos clínicos (códigos de 3 caracteres)

Con el modelo principal de rezagos:

| Subgrupo | Código | Hipótesis |
|---|---|---|
| Deshidratación / depleción de volumen | E86 | Efecto directo del calor, el mayor de todos |
| Insuficiencia renal aguda | N17 | Efecto directo, con rezago de 1–3 días |
| Infarto agudo de miocardio | I21 | Si el calor sube IAM y el capítulo circulatorio baja, la baja del capítulo es composición, no protección |

Se reportan los tres aunque los intervalos sean anchos (E86 y N17 son pequeños).

## C. Cobertura: IMSS-Bienestar

Descriptivo, sin modelo: atenciones por año × institución (3 letras de la CLUES tras la
entidad: SSA, IMB, etc.) y por estado × año. Sirve para ver si la transferencia a IMSS-Bienestar
desde 2023 cambia el volumen reportado de forma abrupta en algunos estados. Si lo hace, la
sensibilidad obvia es repetir el principal con 2012–2022.

## Lo que se espera perder

- A: menos protección contra confusores que varían dentro del año a escala municipal (p. ej.
  cambios de reporte de una unidad a mitad de año). Por eso A es sensibilidad y no principal.
- B: E86 y N17 pueden tener muchos municipio-meses sin casos; `fepois` los descarta y la muestra
  efectiva se reduce.

## D. Heterogeneidad por marginación (añadido 2026-10-17, antes de correr)

Modelo principal de rezagos, estratificado por **terciles del índice de marginación municipal
CONAPO 2020** (terciles por número de municipios, no ponderados por población). Capítulos: los
que mostraron efecto claro en el principal y tienen hipótesis de vulnerabilidad social:
infecciosas, endocrinas, genitourinario, traumatismos, y el total. Se reporta el acumulado 0–14 a
≥ 36 °C por tercil, con su IC, y la diferencia alto − bajo con su EE (los estratos son muestras
independientes, EE de la diferencia = √(EE₁² + EE₃²)).

Hipótesis: efecto mayor en el tercil de alta marginación (menos aire acondicionado, más trabajo
al aire libre, peor acceso a agua). Se reporta aunque salga al revés o plano. Cautela: la
marginación correlaciona con clima (los municipios más marginados están en el sur, cálido y
húmedo), así que una diferencia entre terciles puede reflejar clima de base y no sólo
vulnerabilidad social; el modelo compara dentro del municipio, pero la distribución de días
≥ 36 °C difiere entre terciles.
