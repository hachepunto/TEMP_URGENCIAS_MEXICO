# Especificación comprometida: todos los capítulos con rezagos 0–14

Escrita el 2026-10-16, **antes de correr ningún modelo de esta etapa**. Lo que salga se reporta
con esta especificación; cualquier cambio posterior se registra como sensibilidad, no como
principal.

## Unidad y periodo

Municipio de residencia × día, 2012–2025, ceros explícitos (igual que el piloto). Los 2,457
municipios del shapefile HDX 2021. Daymet omite el 31-dic en años bisiestos: ese día se imputa
con el 30-dic del mismo municipio, para que las ventanas de rezago no tengan huecos.

## Desenlaces (16 modelos)

Los 15 capítulos CIE-10 que usaba el análisis original, por rango de código de 3 caracteres,
más el total de esos 15:

| Capítulo | Códigos |
|---|---|
| Infecciosas y parasitarias | A00–B99 |
| Sangre e inmunidad | D50–D89 |
| Endocrinas, nutricionales y metabólicas | E00–E90 |
| Mentales y del comportamiento | F00–F99 |
| Sistema nervioso | G00–G99 |
| Ojo | H00–H59 |
| Oído | H60–H95 |
| Circulatorio | I00–I99 |
| Respiratorio | J00–J99 |
| Digestivo | K00–K93 |
| Piel | L00–L99 |
| Osteomuscular | M00–M99 |
| Genitourinario | N00–N99 |
| Síntomas y hallazgos anormales | R00–R99 |
| Traumatismos y envenenamientos | S00–T98 |
| **Total de los 15** | |

Excluidos, como en el análisis original: tumores (C00–D48), embarazo (O), perinatal (P),
malformaciones (Q), códigos especiales (U) y factores de contacto (Z).

## Modelo

Rezagos agrupados en ventanas, con conteo de días por bin:

- Bins de Tmax de 3 °C (<12, 12–15, …, 33–36, ≥36), referencia 24–27 °C.
- Ventanas de rezago: 0, 1–3, 4–7, 8–14 días. Para cada ventana w y bin b, el regresor es el
  número de días de la ventana con Tmax en b (0/1 para la ventana 0).
- `fepois(casos ~ Σ_w Σ_{b≠ref} n_{w,b} + i(bin_prcp, mismo día) | cve^año^mes + ent^dow)`,
  errores agrupados por municipio.

## Cantidades reportadas

1. **Efecto acumulado 0–14** de un día en el bin b frente a 24–27 °C:
   β₀ + 3·β₁₋₃ + 4·β₄₋₇ + 7·β₈₋₁₄ (suma de coeficientes por día de rezago), con EE por la
   combinación lineal de la matriz de varianzas. **Cantidad principal: bin ≥ 36 °C.**
2. **Perfil por ventana** (efecto por día de rezago en cada ventana), para distinguir efecto
   real de desplazamiento: coeficientes negativos en ventanas tardías después de uno positivo en
   la ventana 0 indican adelanto de consultas que habrían ocurrido igual.
3. El efecto del mismo día de este modelo, comparado con el del piloto.

Se reportan los 16 modelos, salgan o no significativos. Con 16 comparaciones, un IC 95 % que
apenas excluye 1 en un solo capítulo no se interpreta como hallazgo.

## Lo que se espera perder

- Con efectos fijos mun×año×mes, el efecto del frío con rezagos de 1–3 semanas sólo se ve
  parcialmente (las ventanas de 8–14 días quedan dentro del mismo mes sólo en parte).
- Capítulos chicos (sangre, ojo, oído) pueden tener intervalos muy anchos en los extremos.
- Si el efecto del calor en circulatorio es desplazamiento, la ventana 0 seguirá baja y no
  habrá rebote: este diseño no lo distingue de una reducción real de consultas.
