<!-- Copia de Drive:Claude-remote/temp-urgencias/CLAUDE.md (canónica). No editar aquí: se trae desde el Drive, nunca al revés. -->

# CLAUDE.md — temp-urgencias

Contexto del proyecto y reglas de trabajo. Derivado de `Claude-remote/PLANTILLA_REGLAS_DE_TRABAJO.md`.
**Copia canónica de las reglas: este archivo en `Claude-remote/temp-urgencias/CLAUDE.md`; lo
escribe `CC-fx-ld1`.** Orden de lectura en una sesión nueva: `INDEX.md` → este archivo →
`records/REGISTRO.md` (últimas entradas) → buzones.

---

## Contexto del proyecto

**Pregunta.** ¿Cómo cambia la tasa diaria de atenciones de urgencias en México con la
temperatura, por capítulo CIE-10? Proyecto iniciado por Diana Álvarez (ya no está en el
instituto; repo original `github.com/dialvas/TEMP_URGENCIAS_MEXICO`, jul-2024). Lo retoma
hachepunto (administrador de su espacio) en oct-2026.

**Datos** (todos en fx-ld1, `/STORAGE/genut/dalvarez/`):

| Fuente | Ruta | Notas |
|---|---|---|
| Urgencias DGIS (SSA) 2010–2025, crudo | `PROYECTO_URGENCIAS/DATOS/DATOS_URGENCIAS/` | `MUNRESIDENCIA` existe desde 2012. 2015 y 2018 tienen líneas corruptas. 2023–2025 bajados 2026-10-16 (zips + `SHA256SUMS` en `descarga_2026-10/`). 2026 parcial existe en la DGIS, pero Daymet 2026 aún no. |
| Temperatura/precip diaria por municipio (promedio de polígono) | `TEMPERATURA_MEXICO_MUNICIPAL/day_results/*.rds` (2008–2022, Daymet V4.0, Diana) y `day_results_v4r1/` (tmax 2022–2025, prcp 2023–2025, Daymet V4R1, `00_clima_municipal.R`) | 2,457 municipios × todos los días, sin NA. Llave por nombre (`municipio`, `state`) del shapefile HDX. V4.0 y V4R1 coinciden en 2022. tmax 2010 día 328 sospechoso. |
| Daymet NetCDF Norteamérica diario | `TEMPERATURA_MEXICO_MUNICIPAL/diaria_daymet/` (V4.0, 2008–2022, copia buena) y `diaria_daymet_v4r1/` (V4R1) | La copia que había en `TEMP_URGENCIAS_MEXICO/Datos/Temperaturas/` estaba corrupta y se borró, salvo 4 archivos que complementan días ilegibles de la buena (tmax/tmin 2010, tmin 2011, tmin 2022) y los 2023 de Diana. |
| Polígonos municipales HDX 2021 | `TEMP_URGENCIAS_MEXICO/Datos/municipios/` | `ADM2_PCODE` = `MX` + clave INEGI de 5 dígitos. |
| CLUES, CIE-10, proyecciones CONAPO municipales | `PROYECTO_URGENCIAS/DATOS/*` y `TEMP_URGENCIAS_MEXICO/Datos/*` | |
| Replicación Burke et al. 2018 (NCC) | `NCC2018/` | Modelo del que partió Diana. |

**Herramientas.** R 4.5.2 del env conda `bio` (`~/miniforge/envs/bio`), `data.table`, `arrow`,
`fixest` 0.14.2, `terra` 1.9.50. Correr R con `LC_ALL=C.UTF-8` (el locale por defecto rompe nombres con ñ); para `terra` sin activar el env, `GDAL_DRIVER_PATH=<env>/lib/gdalplugins` y `PROJ_DATA=<env>/share/proj`. Hilos con `NHILOS` (8 por defecto; tope del nodo 55 sumando todos los jobs). NetCDF: env `nctools` (`ncdump`, `netCDF4`).

**Criterio central del análisis.** Panel municipio de **residencia** × día × capítulo con
**ceros explícitos**; Poisson con efectos fijos (`fixest::fepois`), temperatura en bins, efectos
fijos que absorban estacionalidad y cambios de reporte; errores agrupados por municipio.

**Cautelas conocidas.**
- El análisis original (scripts 1–8 de Diana) omitía los municipio-días con cero casos y
  asignaba la exposición al municipio del hospital; sus resultados no son válidos.
- Las bases DGIS cubren sobre todo unidades SSA (no IMSS/ISSSTE): el denominador es la
  población sin seguridad social, no la total.
- 2020–2021: COVID y transición Seguro Popular → INSABI. En 2024 el 67 % de las atenciones pasa a clave IMSS-Bienestar (mismas unidades reetiquetadas).
- **2013 excluido**: MUNRESIDENCIA inválida en la fuente (ver AUDITORIA_2026-10-17). 2012: 26 % sin municipio, por estados/unidades.
- Antecedentes directos: Sarmiento et al. (RFF 25-11) y Aguilar-Gomez et al. (NBER 33491), ambos con municipio del hospital; el trabajo se posiciona como replicación + extensión (ver LITERATURA_2026-10-17).
- Cambios en reporte de unidades a lo largo de los años: no confundir «sin reporte» con «cero».

---

## 0. Principio

**Un archivo, un escritor.** De ahí: territorios (cada carpeta tiene un solo agente que escribe),
buzones (lo que se necesita del territorio ajeno se pide por escrito) y trazabilidad (todo
número de un entregable se rastrea hasta un archivo y una columna). Si una regla estorba, se
cambia este documento; no se salta en silencio.

## 1. Agentes

| Nombre en archivos | Papel | Capacidad |
|---|---|---|
| `CC-fx-ld1` | Agente de cómputo | Claude Code en fx-ld1, shell persistente, datos y pipeline |
| `CD`, `CW`, `CS` | Análisis/redacción o sin ejecución | Claude Desktop / Web / Science: leen la carpeta de la nube y dejan peticiones en buzones |

Reglas para todos: jamás escribir en territorio ajeno; jamás recalcular a mano un número del
pipeline (se pide); un error propio se dice en cuanto se detecta y se corrige; una corrección
de otro agente se evalúa por su argumento, no por inercia ni cortesía.

## 2. Territorios

| Qué | Dónde vive | Quién escribe |
|---|---|---|
| Datos de entrada, pipeline, salidas de cómputo | `fx-ld1:/STORAGE/genut/dalvarez/TEMP_URGENCIAS_MEXICO/` (repo git) | `CC-fx-ld1` |
| Instantánea de resultados (`figures/`, `tables/`, `INDEX.md`) | `Claude-remote/temp-urgencias/` | `CC-fx-ld1`, por subida explícita; los demás sólo leen |
| Este `CLAUDE.md` (reglas, canónico) | `Claude-remote/temp-urgencias/CLAUDE.md` | `CC-fx-ld1`; cambios se proponen en `records/` |
| Scripts propuestos para fx-ld1 | `Claude-remote/temp-urgencias/code/` | quien propone (`CD`/`CW`/`CS`) |
| Bitácora | `records/REGISTRO.md` | `CC-fx-ld1` |
| Buzón de peticiones a `CC-fx-ld1` | `records/PARA_CC-fx-ld1.md` | quien pide |
| Respuestas de `CC-fx-ld1` | `records/DE_CC-fx-ld1.md` | `CC-fx-ld1` |
| Manuscrito | `Claude-remote/temp-urgencias/manuscript/` (`BORRADOR_v0.1.md` + copia Google Docs para lectura) | `CC-fx-ld1` hasta que haya coautores; la copia Docs es sólo lectura/comentarios |
| Código publicable | repo git (fork bajo cuenta/organización por decidir) | `CC-fx-ld1` |

No se crea `docs/` ni `config/` en la nube: métodos y parámetros viven en el repo
(`README.md`, encabezados de los scripts, logs de corrida). Duplicarlos crearía dos escritores.

## 3–4. Carpeta en la nube y cómputo

La nube **recibe resultados, no insumos**. Los datos y el cómputo se quedan en fx-ld1. No hay
sincronización en bloque: `CC-fx-ld1` sube artefactos concretos (una figura, una tabla) y lo
anota en `INDEX.md` con fecha. `historico/<fecha>_<motivo>/` guarda el «antes» de todo cambio
que mueva cifras ya reportadas.

## 5. Buzones

Peticiones numeradas `P1, P2, …` (no se reciclan), agrupadas en rondas, con encabezado de estado
al principio. Cada petición dice qué cambiar, en qué archivo y por qué; si implica cómputo lo
dice en el título. **Nada que consuma horas de servidor arranca sin «AUTORIZADO: adelante con
<X>».** Respuestas punto por punto con el mismo número, distinguiendo «corregido en documentación»
de «recorrido el pipeline». Las peticiones cerradas se marcan *(Cerrada.)* y no se borran.

## 6. Bitácora

`records/REGISTRO.md`, entrada más reciente arriba, con fecha y título que diga lo que pasó.
Incluye: toda conclusión que se mueva (dos cifras y dirección), errores propios corregidos dentro
de la entrada que los contenía con la regla nueva, lo declarado pero no entregado, cifras que
quedaron desactualizadas en otros archivos.

## 7. Pasar trabajo

Quien necesita un análisis deja script o especificación en `code/`; `CC-fx-ld1` lo integra, lo
corre y sube el resultado; quien lo pidió verifica. Cada script trae en su encabezado por qué
existe y qué escribe; cada corrida deja log y versiones de software. Tras cada instantánea
nueva, auditoría cruzada de cifras contra tablas.

## 8. Arrancar otro agente

El agente en sesión escribe un prompt autocontenido: contexto en 3–4 líneas, orden de lectura
(este archivo es la copia canónica), peticiones abiertas con número, reglas de coordinación.

## 9. Reglas ganadas a golpes

Generales (de la plantilla): unir por clave, nunca por posición; un `NA` en resultados es un bug
hasta demostrar lo contrario; comprobar escala antes de agrupar fuentes; no recalcular
estadísticos en el código de figuras; no inventar cifras al resumir; toda cifra se comprueba
contra la tabla que la origina; nunca sobrescribir sin comparar; compromiso previo de la
especificación principal antes de ver resultados; no fijar `setwd()` en scripts.

De este proyecto:
- **No leer CSV crudos de la DGIS sin contar filas descartadas.** `fread` se detuvo en silencio
  (sólo un *warning*) en una línea corrupta y dejó 2015 y 2018 a la mitad (2026-10-16). Se filtra
  por número de campos y se registra cuántas líneas se descartan.
- **Un panel de conteos se construye con ceros explícitos.** Agregar con `group_by() %>% n()`
  borra los días sin casos y sesga cualquier modelo de dosis-respuesta (error del análisis
  original).
- **Exposición en el municipio de residencia, no del hospital** (desde 2012 existe
  `MUNRESIDENCIA`).
- **Categorías de `fixest::i()` como enteros, no como etiquetas con corchetes.** Con
  `ref = "[24,27)"` los nombres de término salen corruptos y emparejar por nombre falla en
  silencio. Se usa el código entero del bin y se mapea a la etiqueta por llave.
- **Mismo nombre y tamaño no es mismo archivo.** 32 de 39 NetCDF «duplicados» diferían; la copia
  del repo estaba corrupta. Antes de borrar un duplicado: `cmp` completo y, si difieren,
  decodificar ambos.
- **No usar `pgrep -f`/`pkill -f` con un patrón que esté en la propia línea de comandos.**
- **Una columna con el nombre correcto no garantiza el contenido correcto**: validar rangos y
  cardinalidad por año (2013: MUNRESIDENCIA = entidad en el 100 %).
- **No editar un script mientras una corrida suya está en curso**: R lo lee expresión por expresión.
- **La clasificación cualitativa de resultados se calcula en código desde la tabla**, no a ojo desde
  la figura ni de memoria; toda cifra del borrador se coteja contra el CSV antes de subir.
- **Índices compuestos: comprobar la dirección** (CONAPO 2020: IM alto = menos marginación).
- **Nombres de archivo con ñ en NFD** (hechos en macOS): abrir con `list.files()`, no tecleando
  el nombre.

## 10. Coautores humanos

Manuscrito con control de cambios, re-subido sobre el mismo archivo. `figures/` son salidas del
pipeline. `records/interno/` es material de trabajo, no circula.
