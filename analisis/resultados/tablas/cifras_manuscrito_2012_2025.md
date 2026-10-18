# Cifras del manuscrito — generado por 30_cifras_manuscrito.R el 2026-10-18 08:58

## Muestra y exposición (clima_ventanas_2012_2025.parquet, sin 2012-12-26..2013-12-25)

- municipios: 2457; días: 4749; municipio-días por desenlace: 11,668,293
- municipio-días con Tmax >= 36: 4.18%; municipios que nunca llegan a >= 36: 596
- municipio-días con Tmax < 12: 0.40%
- % de días >= 36 por tercil de marginación: M1 6.40; M2 3.45; M3 2.69

### Atenciones fuera del municipio de residencia

Fuente: `residencia_vs_hospital.csv`

| grupo | n | pct_otro_municipio |
|---|---|---|
| total | 89334469 | 19.42 |
| marg1 | 66850102 | 16.65 |
| marg2 | 15813153 | 23.69 |
| marg3 | 6660645 | 36.88 |

### Tabla 1: >= 36 °C vs 24-27 °C

Fuente: `rezagos_2012_2025.csv`

| cap | mismo_dia | acumulado_0_14 | ic_bidireccional | signo |
|---|---|---|---|---|
| infecciosas | 1.121 | 1.178 [1.143, 1.215] | [1.134, 1.224] | sube |
| endocrinas | 1.135 | 1.155 [1.119, 1.191] | [1.110, 1.201] | sube |
| genitourinario | 1.069 | 1.140 [1.109, 1.171] | [1.103, 1.178] | sube |
| sangre | 1.068 | 1.138 [1.064, 1.217] | [1.059, 1.223] | sube |
| piel | 1.059 | 1.131 [1.093, 1.171] | [1.089, 1.176] | sube |
| traumatismos | 1.117 | 1.121 [1.099, 1.143] | [1.091, 1.151] | sube |
| sintomas | 1.072 | 1.103 [1.075, 1.131] | [1.070, 1.136] | sube |
| ojo | 1.038 | 1.093 [1.024, 1.167] | [1.020, 1.172] | sube |
| mentales | 1.099 | 1.083 [1.049, 1.119] | [1.042, 1.126] | sube |
| oido | 1.022 | 1.057 [1.003, 1.115] | [1.000, 1.118] | sube |
| total | 1.067 | 1.035 [1.017, 1.053] | [1.010, 1.060] | sube |
| digestivo | 1.011 | 1.024 [1.001, 1.049] | [0.995, 1.055] | sube |
| osteomuscular | 1.033 | 1.019 [0.983, 1.057] | [0.978, 1.063] | nulo |
| nervioso | 1.044 | 0.953 [0.915, 0.993] | [0.911, 0.997] | baja |
| circulatorio | 0.979 | 0.895 [0.866, 0.926] | [0.862, 0.930] | baja |
| respiratorio | 1.028 | 0.779 [0.752, 0.808] | [0.744, 0.817] | baja |

- capítulos que suben / bajan / nulos (acumulado, IC por municipio): 11 / 3 / 1
- ensanchamiento del IC bidireccional: 6% a 43%; cambios de significancia: 1

### Frío < 12 °C, acumulado 0-14 (principal)

Fuente: `rezagos_2012_2025.csv`

| cap | acumulado_menos12 |
|---|---|
| infecciosas | 0.793 [0.710, 0.887] |
| respiratorio | 0.830 [0.767, 0.897] |
| sangre | 0.944 [0.759, 1.174] |
| total | 0.947 [0.892, 1.005] |
| osteomuscular | 0.963 [0.871, 1.064] |
| traumatismos | 0.964 [0.891, 1.043] |
| digestivo | 0.978 [0.908, 1.054] |
| oido | 0.980 [0.841, 1.143] |
| piel | 1.006 [0.879, 1.150] |
| sintomas | 1.021 [0.928, 1.122] |
| endocrinas | 1.023 [0.927, 1.129] |
| ojo | 1.032 [0.836, 1.272] |
| genitourinario | 1.032 [0.945, 1.128] |
| mentales | 1.046 [0.928, 1.178] |
| circulatorio | 1.096 [0.998, 1.203] |
| nervioso | 1.104 [0.970, 1.256] |

### Forma de la curva acumulada de 24-27 a >= 36 °C

Fuente: `rezagos_2012_2025.csv`

| cap | creciente | decreciente | bin_max |
|---|---|---|---|
| circulatorio | FALSE | TRUE | [24,27) |
| digestivo | TRUE | FALSE | [36, Inf) |
| endocrinas | TRUE | FALSE | [36, Inf) |
| genitourinario | TRUE | FALSE | [36, Inf) |
| infecciosas | FALSE | FALSE | [33,36) |
| mentales | TRUE | FALSE | [36, Inf) |
| nervioso | FALSE | TRUE | [24,27) |
| oido | FALSE | FALSE | [36, Inf) |
| ojo | TRUE | FALSE | [36, Inf) |
| osteomuscular | FALSE | FALSE | [36, Inf) |
| piel | TRUE | FALSE | [36, Inf) |
| respiratorio | FALSE | TRUE | [24,27) |
| sangre | TRUE | FALSE | [36, Inf) |
| sintomas | FALSE | FALSE | [33,36) |
| total | FALSE | FALSE | [33,36) |
| traumatismos | TRUE | FALSE | [36, Inf) |

### Dinámica por ventana a >= 36 °C (IRR por día de rezago)

Fuente: `rezagos_2012_2025.csv`

| cap | v0 | v1_3 | v4_7 | v8_14 | acumulado | patron |
|---|---|---|---|---|---|---|
| mentales | 1.099 | 1.012 | 0.995 | 0.996 | 1.083 | adelanto parcial |
| oido | 1.022 | 1.006 | 1.018 | 0.992 | 1.057 | adelanto parcial |
| total | 1.067 | 1.004 | 0.997 | 0.996 | 1.035 | adelanto parcial |
| traumatismos | 1.117 | 1.017 | 0.995 | 0.996 | 1.121 | adelanto parcial |
| circulatorio | 0.979 | 0.981 | 0.995 | 0.998 | 0.895 | baja sin rebote |
| nervioso | 1.044 | 0.980 | 1.000 | 0.996 | 0.953 | caída tardía mayor que el exceso |
| respiratorio | 1.028 | 0.985 | 0.980 | 0.979 | 0.779 | caída tardía mayor que el exceso |
| digestivo | 1.011 | 0.999 | 1.003 | 1.001 | 1.024 | exceso neto |
| endocrinas | 1.135 | 1.011 | 0.997 | 0.999 | 1.155 | exceso neto |
| genitourinario | 1.069 | 1.010 | 1.006 | 1.002 | 1.140 | exceso neto |
| infecciosas | 1.121 | 1.014 | 1.006 | 0.998 | 1.178 | exceso neto |
| ojo | 1.038 | 1.013 | 1.007 | 0.998 | 1.093 | exceso neto |
| osteomuscular | 1.033 | 0.999 | 1.000 | 0.999 | 1.019 | exceso neto |
| piel | 1.059 | 1.007 | 1.000 | 1.006 | 1.131 | exceso neto |
| sangre | 1.068 | 1.007 | 1.000 | 1.006 | 1.138 | exceso neto |
| sintomas | 1.072 | 1.010 | 1.001 | 1.000 | 1.103 | exceso neto |

### Subgrupos E86 / N17 / I21

Fuente: `rezagos_subgrupos_2012_2025.csv`

| cap | cantidad | bin | irr |
|---|---|---|---|
| E86_deshidratacion | acumulado_0_14 | [30,33) | 1.221 [1.148, 1.299] |
| E86_deshidratacion | v0 | [30,33) | 1.137 [1.109, 1.166] |
| E86_deshidratacion | v1_3 | [30,33) | 1.014 [1.001, 1.026] |
| E86_deshidratacion | v4_7 | [30,33) | 1.007 [0.998, 1.016] |
| E86_deshidratacion | v8_14 | [30,33) | 1.001 [0.994, 1.007] |
| E86_deshidratacion | acumulado_0_14 | [33,36) | 1.451 [1.348, 1.562] |
| E86_deshidratacion | v0 | [33,36) | 1.270 [1.232, 1.309] |
| E86_deshidratacion | v1_3 | [33,36) | 1.025 [1.009, 1.040] |
| E86_deshidratacion | v4_7 | [33,36) | 1.008 [0.997, 1.019] |
| E86_deshidratacion | v8_14 | [33,36) | 1.004 [0.996, 1.012] |
| E86_deshidratacion | acumulado_0_14 | [36, Inf) | 2.105 [1.908, 2.323] |
| E86_deshidratacion | v0 | [36, Inf) | 1.490 [1.429, 1.554] |
| E86_deshidratacion | v1_3 | [36, Inf) | 1.074 [1.055, 1.094] |
| E86_deshidratacion | v4_7 | [36, Inf) | 1.022 [1.008, 1.036] |
| E86_deshidratacion | v8_14 | [36, Inf) | 1.006 [0.997, 1.015] |
| I21_infarto | acumulado_0_14 | [30,33) | 0.966 [0.866, 1.078] |
| I21_infarto | v0 | [30,33) | 1.048 [1.006, 1.092] |
| I21_infarto | v1_3 | [30,33) | 1.002 [0.984, 1.020] |
| I21_infarto | v4_7 | [30,33) | 0.985 [0.972, 0.998] |
| I21_infarto | v8_14 | [30,33) | 0.996 [0.987, 1.006] |
| I21_infarto | acumulado_0_14 | [33,36) | 0.943 [0.834, 1.066] |
| I21_infarto | v0 | [33,36) | 1.059 [1.003, 1.117] |
| I21_infarto | v1_3 | [33,36) | 0.990 [0.968, 1.013] |
| I21_infarto | v4_7 | [33,36) | 0.994 [0.977, 1.010] |
| I21_infarto | v8_14 | [33,36) | 0.991 [0.979, 1.004] |
| I21_infarto | acumulado_0_14 | [36, Inf) | 0.982 [0.832, 1.160] |
| I21_infarto | v0 | [36, Inf) | 1.023 [0.960, 1.090] |
| I21_infarto | v1_3 | [36, Inf) | 1.004 [0.974, 1.035] |
| I21_infarto | v4_7 | [36, Inf) | 0.993 [0.972, 1.015] |
| I21_infarto | v8_14 | [36, Inf) | 0.996 [0.980, 1.013] |
| N17_renal_aguda | acumulado_0_14 | [30,33) | 0.979 [0.810, 1.183] |
| N17_renal_aguda | v0 | [30,33) | 1.065 [0.994, 1.142] |
| N17_renal_aguda | v1_3 | [30,33) | 1.002 [0.973, 1.033] |
| N17_renal_aguda | v4_7 | [30,33) | 0.998 [0.974, 1.024] |
| N17_renal_aguda | v8_14 | [30,33) | 0.988 [0.970, 1.006] |
| N17_renal_aguda | acumulado_0_14 | [33,36) | 0.916 [0.747, 1.124] |
| N17_renal_aguda | v0 | [33,36) | 1.138 [1.053, 1.231] |
| N17_renal_aguda | v1_3 | [33,36) | 0.991 [0.955, 1.029] |
| N17_renal_aguda | v4_7 | [33,36) | 0.985 [0.955, 1.015] |
| N17_renal_aguda | v8_14 | [33,36) | 0.982 [0.962, 1.002] |
| N17_renal_aguda | acumulado_0_14 | [36, Inf) | 0.945 [0.747, 1.196] |
| N17_renal_aguda | v0 | [36, Inf) | 1.148 [1.043, 1.264] |
| N17_renal_aguda | v1_3 | [36, Inf) | 0.986 [0.948, 1.025] |
| N17_renal_aguda | v4_7 | [36, Inf) | 1.005 [0.972, 1.039] |
| N17_renal_aguda | v8_14 | [36, Inf) | 0.976 [0.955, 0.997] |

### Residencia vs hospital, acumulado >= 36

Fuente: `rezagos_hospital_2012_2025.csv`

| cap | residencia | hospital | dif |
|---|---|---|---|
| sangre | 1.138 | 1.188 | +0.050 |
| mentales | 1.083 | 1.048 | -0.035 |
| endocrinas | 1.155 | 1.128 | -0.027 |
| infecciosas | 1.178 | 1.205 | +0.027 |
| nervioso | 0.953 | 0.927 | -0.026 |
| ojo | 1.093 | 1.079 | -0.014 |
| piel | 1.131 | 1.143 | +0.012 |
| osteomuscular | 1.019 | 1.008 | -0.011 |
| respiratorio | 0.779 | 0.772 | -0.008 |
| digestivo | 1.024 | 1.018 | -0.007 |
| sintomas | 1.103 | 1.097 | -0.006 |
| total | 1.035 | 1.030 | -0.005 |
| oido | 1.057 | 1.062 | +0.004 |
| traumatismos | 1.121 | 1.118 | -0.003 |
| genitourinario | 1.140 | 1.138 | -0.002 |
| circulatorio | 0.895 | 0.895 | -0.000 |

### D: terciles de marginación, >= 36

Fuente: `marginacion_2012_2025.csv`

| cap | tercil | irr | M3_vs_M1 |
|---|---|---|---|
| circulatorio | 1 | 0.892 [0.857, 0.929] | 0.995 [0.895, 1.106] |
| circulatorio | 2 | 0.916 [0.858, 0.978] | 0.995 [0.895, 1.106] |
| circulatorio | 3 | 0.888 [0.805, 0.979] | 0.995 [0.895, 1.106] |
| digestivo | 1 | 1.015 [0.986, 1.044] | 1.012 [0.941, 1.087] |
| digestivo | 2 | 1.070 [1.020, 1.123] | 1.012 [0.941, 1.087] |
| digestivo | 3 | 1.026 [0.960, 1.097] | 1.012 [0.941, 1.087] |
| endocrinas | 1 | 1.167 [1.121, 1.214] | 0.923 [0.832, 1.023] |
| endocrinas | 2 | 1.162 [1.097, 1.231] | 0.923 [0.832, 1.023] |
| endocrinas | 3 | 1.076 [0.979, 1.184] | 0.923 [0.832, 1.023] |
| genitourinario | 1 | 1.134 [1.097, 1.172] | 0.995 [0.911, 1.085] |
| genitourinario | 2 | 1.176 [1.118, 1.237] | 0.995 [0.911, 1.085] |
| genitourinario | 3 | 1.128 [1.040, 1.223] | 0.995 [0.911, 1.085] |
| infecciosas | 1 | 1.178 [1.134, 1.223] | 0.933 [0.846, 1.029] |
| infecciosas | 2 | 1.219 [1.152, 1.290] | 0.933 [0.846, 1.029] |
| infecciosas | 3 | 1.099 [1.004, 1.202] | 0.933 [0.846, 1.029] |
| mentales | 1 | 1.086 [1.049, 1.126] | 0.871 [0.751, 1.010] |
| mentales | 2 | 1.119 [1.027, 1.220] | 0.871 [0.751, 1.010] |
| mentales | 3 | 0.946 [0.819, 1.093] | 0.871 [0.751, 1.010] |
| nervioso | 1 | 0.954 [0.910, 0.999] | 0.887 [0.770, 1.020] |
| nervioso | 2 | 1.009 [0.917, 1.109] | 0.887 [0.770, 1.020] |
| nervioso | 3 | 0.845 [0.741, 0.965] | 0.887 [0.770, 1.020] |
| oido | 1 | 1.024 [0.961, 1.091] | 1.266 [1.047, 1.530] |
| oido | 2 | 1.120 [1.016, 1.235] | 1.266 [1.047, 1.530] |
| oido | 3 | 1.297 [1.085, 1.550] | 1.266 [1.047, 1.530] |
| ojo | 1 | 1.093 [1.013, 1.179] | 0.987 [0.775, 1.257] |
| ojo | 2 | 1.087 [0.924, 1.279] | 0.987 [0.775, 1.257] |
| ojo | 3 | 1.079 [0.857, 1.357] | 0.987 [0.775, 1.257] |
| osteomuscular | 1 | 1.014 [0.972, 1.058] | 1.028 [0.910, 1.161] |
| osteomuscular | 2 | 1.048 [0.972, 1.129] | 1.028 [0.910, 1.161] |
| osteomuscular | 3 | 1.042 [0.930, 1.168] | 1.028 [0.910, 1.161] |
| piel | 1 | 1.127 [1.083, 1.173] | 0.932 [0.811, 1.072] |
| piel | 2 | 1.198 [1.103, 1.302] | 0.932 [0.811, 1.072] |
| piel | 3 | 1.051 [0.920, 1.201] | 0.932 [0.811, 1.072] |
| respiratorio | 1 | 0.769 [0.737, 0.802] | 0.996 [0.903, 1.099] |
| respiratorio | 2 | 0.833 [0.773, 0.898] | 0.996 [0.903, 1.099] |
| respiratorio | 3 | 0.766 [0.702, 0.837] | 0.996 [0.903, 1.099] |
| sangre | 1 | 1.140 [1.052, 1.237] | 0.872 [0.681, 1.117] |
| sangre | 2 | 1.198 [1.045, 1.372] | 0.872 [0.681, 1.117] |
| sangre | 3 | 0.995 [0.787, 1.257] | 0.872 [0.681, 1.117] |
| sintomas | 1 | 1.089 [1.057, 1.122] | 1.093 [0.999, 1.196] |
| sintomas | 2 | 1.141 [1.087, 1.199] | 1.093 [0.999, 1.196] |
| sintomas | 3 | 1.191 [1.093, 1.297] | 1.093 [0.999, 1.196] |
| total | 1 | 1.029 [1.008, 1.051] | 0.986 [0.941, 1.034] |
| total | 2 | 1.072 [1.039, 1.106] | 0.986 [0.941, 1.034] |
| total | 3 | 1.015 [0.973, 1.059] | 0.986 [0.941, 1.034] |
| traumatismos | 1 | 1.120 [1.093, 1.147] | 0.975 [0.924, 1.029] |
| traumatismos | 2 | 1.148 [1.107, 1.191] | 0.975 [0.924, 1.029] |
| traumatismos | 3 | 1.092 [1.040, 1.146] | 0.975 [0.924, 1.029] |

### E: M3 vs M1 a clima de base constante

Fuente: `clima_marg_2012_2025.csv`

| cap | clima | bin | M3_vs_M1 | excluye_1 |
|---|---|---|---|---|
| endocrinas | 1 | [33,36) | 0.795 [0.513, 1.234] | FALSE |
| endocrinas | 2 | [33,36) | 0.810 [0.706, 0.929] | TRUE |
| endocrinas | 3 | [33,36) | 0.960 [0.814, 1.132] | FALSE |
| genitourinario | 1 | [33,36) | 0.901 [0.649, 1.252] | FALSE |
| genitourinario | 2 | [33,36) | 1.018 [0.913, 1.136] | FALSE |
| genitourinario | 3 | [33,36) | 1.063 [0.934, 1.210] | FALSE |
| infecciosas | 1 | [33,36) | 0.711 [0.534, 0.948] | TRUE |
| infecciosas | 2 | [33,36) | 1.047 [0.933, 1.175] | FALSE |
| infecciosas | 3 | [33,36) | 0.929 [0.813, 1.062] | FALSE |
| total | 1 | [33,36) | 0.881 [0.804, 0.966] | TRUE |
| total | 2 | [33,36) | 0.967 [0.917, 1.019] | FALSE |
| total | 3 | [33,36) | 1.064 [0.998, 1.134] | FALSE |
| traumatismos | 1 | [33,36) | 0.880 [0.752, 1.031] | FALSE |
| traumatismos | 2 | [33,36) | 0.933 [0.856, 1.018] | FALSE |
| traumatismos | 3 | [33,36) | 1.014 [0.927, 1.110] | FALSE |
| endocrinas | 2 | [36, Inf) | 1.055 [0.789, 1.410] | FALSE |
| endocrinas | 3 | [36, Inf) | 0.930 [0.775, 1.115] | FALSE |
| genitourinario | 2 | [36, Inf) | 0.929 [0.718, 1.202] | FALSE |
| genitourinario | 3 | [36, Inf) | 1.062 [0.921, 1.225] | FALSE |
| infecciosas | 2 | [36, Inf) | 0.962 [0.767, 1.207] | FALSE |
| infecciosas | 3 | [36, Inf) | 0.947 [0.819, 1.096] | FALSE |
| total | 2 | [36, Inf) | 1.011 [0.903, 1.131] | FALSE |
| total | 3 | [36, Inf) | 1.035 [0.957, 1.120] | FALSE |
| traumatismos | 2 | [36, Inf) | 1.072 [0.923, 1.245] | FALSE |
| traumatismos | 3 | [36, Inf) | 0.980 [0.891, 1.077] | FALSE |

### E: IRR >= 36 por clima (columnas C) y marginación

Fuente: `clima_marg_2012_2025.csv`

| cap | marg | 2 | 3 |
|---|---|---|---|
| endocrinas | 1 | 1.059 | 1.185 |
| endocrinas | 2 | 1.227 | 1.178 |
| endocrinas | 3 | 1.116 | 1.102 |
| genitourinario | 1 | 1.141 | 1.154 |
| genitourinario | 2 | 1.115 | 1.245 |
| genitourinario | 3 | 1.060 | 1.226 |
| infecciosas | 1 | 1.037 | 1.264 |
| infecciosas | 2 | 1.087 | 1.293 |
| infecciosas | 3 | 0.998 | 1.197 |
| total | 1 | 1.023 | 1.056 |
| total | 2 | 1.044 | 1.153 |
| total | 3 | 1.034 | 1.093 |
| traumatismos | 1 | 1.083 | 1.149 |
| traumatismos | 2 | 1.114 | 1.266 |
| traumatismos | 3 | 1.161 | 1.126 |

### Tamaño de celdas clima × marginación

Fuente: `celdas_clima_marg.csv`

| clima | marg | municipios | dias_33_36 | dias_ge36 | mun_con_ge36 | ge36_identificado |
|---|---|---|---|---|---|---|
| 1 | 1 | 271 | 6920 | 159 | 56 | 0 |
| 1 | 2 | 308 | 11175 | 175 | 90 | 0 |
| 1 | 3 | 244 | 10676 | 195 | 85 | 0 |
| 2 | 1 | 260 | 57700 | 8053 | 260 | 1 |
| 2 | 2 | 245 | 59061 | 6849 | 245 | 1 |
| 2 | 3 | 310 | 79315 | 6661 | 306 | 1 |
| 3 | 1 | 288 | 343614 | 240538 | 288 | 1 |
| 3 | 2 | 266 | 457407 | 127050 | 266 | 1 |
| 3 | 3 | 265 | 488490 | 97910 | 265 | 1 |

### A: efectos fijos mun×año + edo×semana + edo×dow

Fuente: `rezagos_fe-anio_semana_2012_2025.csv`

| cap | bin | irr |
|---|---|---|
| circulatorio | [-Inf,12) | 0.856 [0.778, 0.942] |
| digestivo | [-Inf,12) | 0.768 [0.713, 0.827] |
| endocrinas | [-Inf,12) | 0.791 [0.715, 0.875] |
| genitourinario | [-Inf,12) | 0.798 [0.737, 0.865] |
| infecciosas | [-Inf,12) | 0.743 [0.659, 0.837] |
| mentales | [-Inf,12) | 0.859 [0.781, 0.945] |
| nervioso | [-Inf,12) | 0.873 [0.784, 0.972] |
| oido | [-Inf,12) | 0.778 [0.663, 0.913] |
| ojo | [-Inf,12) | 0.746 [0.618, 0.901] |
| osteomuscular | [-Inf,12) | 0.821 [0.743, 0.907] |
| piel | [-Inf,12) | 0.798 [0.711, 0.896] |
| respiratorio | [-Inf,12) | 0.705 [0.636, 0.782] |
| sangre | [-Inf,12) | 0.740 [0.617, 0.887] |
| sintomas | [-Inf,12) | 0.786 [0.703, 0.878] |
| total | [-Inf,12) | 0.747 [0.701, 0.796] |
| traumatismos | [-Inf,12) | 0.741 [0.689, 0.797] |
| circulatorio | [36, Inf) | 0.894 [0.869, 0.919] |
| digestivo | [36, Inf) | 0.971 [0.949, 0.994] |
| endocrinas | [36, Inf) | 1.112 [1.077, 1.148] |
| genitourinario | [36, Inf) | 1.084 [1.055, 1.113] |
| infecciosas | [36, Inf) | 0.991 [0.939, 1.046] |
| mentales | [36, Inf) | 1.001 [0.966, 1.036] |
| nervioso | [36, Inf) | 0.915 [0.882, 0.948] |
| oido | [36, Inf) | 1.077 [1.018, 1.139] |
| ojo | [36, Inf) | 1.036 [0.981, 1.095] |
| osteomuscular | [36, Inf) | 0.989 [0.956, 1.023] |
| piel | [36, Inf) | 1.043 [1.006, 1.082] |
| respiratorio | [36, Inf) | 0.897 [0.854, 0.941] |
| sangre | [36, Inf) | 1.064 [1.005, 1.126] |
| sintomas | [36, Inf) | 1.044 [0.999, 1.091] |
| total | [36, Inf) | 1.005 [0.979, 1.031] |
| traumatismos | [36, Inf) | 1.060 [1.037, 1.084] |

- sin 2012 (desde 2014): máx |dif| acumulado >= 36 = 0.024 (sangre); cambios de signo/significancia ver tabla

### Ventanas a 30 días, >= 36

Fuente: `rezagos_v30_2012_2025.csv`

| cap | acumulado_0_30 |
|---|---|
| circulatorio | 0.889 [0.853, 0.927] |
| infecciosas | 1.131 [1.071, 1.194] |
| nervioso | 0.986 [0.929, 1.047] |
| respiratorio | 0.649 [0.615, 0.685] |
| total | 1.026 [1.002, 1.049] |

- H calor_36: 64/164 con q < 0.05 (44 suben, 20 bajan); controles Z con q < 0.05: 2/11

### H: códigos con q < 0.05, calor_36

Fuente: `codigos_fdr_2012_2025.csv`

| cie3 | capitulo | nombre | irr | irr_contraido | q |
|---|---|---|---|---|---|
| E86 | endocrinas | DEPLECIÓN DEL VOLUMEN | 2.105 [1.908, 2.323] | 2.064 | 6.9e-48 |
| E87 | endocrinas | OTROS TRASTORNOS DE LOS LÍQUIDOS, DE LOS ELEC | 1.873 [1.635, 2.145] | 1.818 | 3.2e-18 |
| A97 | infecciosas | DENGUE | 1.822 [1.531, 2.168] | 1.643 | 1.4e-10 |
| R04 | sintomas | HEMORRAGIA DE LAS VÍAS RESPIRATORIAS | 1.749 [1.560, 1.961] | 1.641 | 3.1e-20 |
| N23 | genitourinario | CÓLICO RENAL, NO ESPECIFICADO | 1.572 [1.443, 1.711] | 1.538 | 1.1e-23 |
| A90 | infecciosas | FIEBRE DEL DENGUE [DENGUE CLÁSICO] | 1.979 [1.430, 2.739] | 1.507 | 2.3e-04 |
| T63 | traumatismos | EFECTO TÓXICO DEL CONTACTO CON ANIMALES VENEN | 1.521 [1.441, 1.606] | 1.491 | 4.9e-50 |
| R50 | sintomas | FIEBRE DE OTRO ORIGEN Y DE ORIGEN DESCONOCIDO | 1.401 [1.313, 1.495] | 1.384 | 8.7e-23 |
| N20 | genitourinario | CÁLCULO DEL RIÑÓN Y DEL URÉTER | 1.401 [1.276, 1.538] | 1.378 | 1.6e-11 |
| R42 | sintomas | MAREO Y DESVANECIMIENTO | 1.278 [1.150, 1.419] | 1.255 | 3.5e-05 |
| I87 | circulatorio | OTROS TRASTORNOS DE LAS VENAS | 1.317 [1.138, 1.525] | 1.240 | 1.1e-03 |
| S91 | traumatismos | HERIDA DEL TOBILLO Y DEL PIE | 1.252 [1.149, 1.364] | 1.228 | 2.0e-06 |
| S51 | traumatismos | HERIDA DEL ANTEBRAZO Y DEL CODO | 1.250 [1.116, 1.400] | 1.212 | 6.2e-04 |
| T07 | traumatismos | TRAUMATISMOS MÚLTIPLES, NO ESPECIFICADOS | 1.225 [1.118, 1.342] | 1.202 | 8.5e-05 |
| T14 | traumatismos | TRAUMATISMO DE REGIONES NO ESPECIFICADAS DEL | 1.187 [1.120, 1.259] | 1.180 | 6.3e-08 |
| N12 | genitourinario | NEFRITIS TUBULOINTERSTICIAL, NO ESPECIFICADA | 1.182 [1.077, 1.298] | 1.179 | 2.0e-03 |
| N39 | genitourinario | OTROS TRASTORNOS DEL SISTEMA URINARIO | 1.174 [1.132, 1.217] | 1.173 | 5.0e-17 |
| N94 | genitourinario | DOLOR Y OTRAS AFECCIONES RELACIONADAS CON LOS | 1.177 [1.049, 1.321] | 1.173 | 1.7e-02 |
| T78 | traumatismos | EFECTOS ADVERSOS, NO CLASIFICADOS EN OTRA PAR | 1.185 [1.092, 1.287] | 1.172 | 3.0e-04 |
| R52 | sintomas | DOLOR, NO CLASIFICADO EN OTRA PARTE | 1.163 [1.078, 1.255] | 1.158 | 5.6e-04 |
| D64 | sangre | OTRAS ANEMIAS | 1.165 [1.076, 1.261] | 1.156 | 8.0e-04 |
| A09 | infecciosas | DIARREA Y GASTROENTERITIS DE PRESUNTO ORIGEN | 1.143 [1.104, 1.184] | 1.143 | 1.1e-12 |
| S81 | traumatismos | HERIDA DE LA PIERNA | 1.150 [1.065, 1.243] | 1.143 | 1.8e-03 |
| L03 | piel | CELULITIS | 1.143 [1.045, 1.251] | 1.141 | 1.2e-02 |
| L20 | piel | DERMATITIS ATÓPICA | 1.175 [1.046, 1.321] | 1.141 | 2.0e-02 |
| L30 | piel | OTRAS DERMATITIS | 1.208 [1.062, 1.374] | 1.141 | 1.3e-02 |
| L50 | piel | URTICARIA | 1.171 [1.057, 1.297] | 1.141 | 8.8e-03 |
| S92 | traumatismos | FRACTURA DEL PIE, EXCEPTO DEL TOBILLO | 1.151 [1.024, 1.294] | 1.136 | 4.8e-02 |
| O26 | embarazo | ATENCIÓN A LA MADRE POR OTRAS COMPLICACIONES | 1.313 [1.125, 1.532] | 1.134 | 2.4e-03 |
| H10 | ojo | CONJUNTIVITIS | 1.133 [1.038, 1.238] | 1.125 | 1.7e-02 |
| O75 | embarazo | OTRAS COMPLICACIONES DEL TRABAJO DE PARTO Y D | 1.263 [1.091, 1.461] | 1.124 | 6.2e-03 |
| F32 | mentales | EPISODIO DEPRESIVO | 1.183 [1.071, 1.307] | 1.118 | 3.5e-03 |
| S09 | traumatismos | OTROS TRAUMATISMOS Y LOS NO ESPECIFICADOS DE | 1.117 [1.028, 1.213] | 1.113 | 2.5e-02 |
| O62 | embarazo | ANORMALIDADES DE LA DINÁMICA DEL TRABAJO DE P | 1.172 [1.043, 1.317] | 1.105 | 2.2e-02 |
| S01 | traumatismos | HERIDA DE LA CABEZA | 1.093 [1.043, 1.145] | 1.092 | 9.8e-04 |
| T00 | traumatismos | TRAUMATISMOS SUPERFICIALES QUE AFECTAN MÚLTIP | 1.092 [1.031, 1.157] | 1.092 | 9.7e-03 |
| R11 | sintomas | NÁUSEA Y VÓMITO | 1.089 [1.018, 1.166] | 1.089 | 3.7e-02 |
| K81 | digestivo | COLECISTITIS | 1.111 [1.048, 1.177] | 1.088 | 1.8e-03 |
| O23 | embarazo | INFECCIÓN DE LAS VÍAS GENITOURINARIAS EN EL E | 1.090 [1.038, 1.145] | 1.082 | 2.4e-03 |
| E11 | endocrinas | DIABETES MELLITUS TIPO 2 | 1.074 [1.028, 1.121] | 1.074 | 5.0e-03 |
| K52 | digestivo | OTRAS COLITIS Y GASTROENTERITIS NO INFECCIOSA | 1.098 [1.022, 1.179] | 1.072 | 2.8e-02 |
| Z71 | Z_control | PERSONAS EN CONTACTO CON LOS SERVICIOS DE SAL | 1.116 [1.031, 1.209] | 1.067 | 2.0e-02 |
| Z48 | Z_control | OTROS CUIDADOS POSTERIORES A LA CIRUGÍA | 1.131 [1.025, 1.248] | 1.064 | 3.7e-02 |
| R10 | sintomas | DOLOR ABDOMINAL Y PÉLVICO | 1.062 [1.026, 1.099] | 1.062 | 2.4e-03 |
| K92 | digestivo | OTRAS ENFERMEDADES DEL SISTEMA DIGESTIVO | 0.894 [0.817, 0.978] | 0.953 | 3.7e-02 |
| G43 | nervioso | MIGRAÑA | 0.876 [0.800, 0.959] | 0.920 | 1.3e-02 |
| S72 | traumatismos | FRACTURA DEL FÉMUR | 0.888 [0.814, 0.969] | 0.913 | 2.2e-02 |
| J02 | respiratorio | FARINGITIS AGUDA | 0.889 [0.848, 0.931] | 0.884 | 4.9e-06 |
| N18 | genitourinario | ENFERMEDAD RENAL CRÓNICA | 0.856 [0.784, 0.934] | 0.874 | 2.1e-03 |
| I10 | circulatorio | HIPERTENSIÓN ESENCIAL (PRIMARIA) | 0.860 [0.827, 0.894] | 0.860 | 4.7e-13 |
| J44 | respiratorio | OTRAS ENFERMEDADES PULMONARES OBSTRUCTIVAS CR | 0.869 [0.800, 0.944] | 0.858 | 3.6e-03 |
| J03 | respiratorio | AMIGDALITIS AGUDA | 0.829 [0.762, 0.902] | 0.824 | 8.5e-05 |
| J06 | respiratorio | INFECCIONES AGUDAS DE LAS VÍAS RESPIRATORIAS | 0.823 [0.779, 0.868] | 0.821 | 1.6e-11 |
| I50 | circulatorio | INSUFICIENCIA CARDÍACA | 0.755 [0.669, 0.852] | 0.768 | 3.7e-05 |
| J45 | respiratorio | ASMA | 0.759 [0.708, 0.812] | 0.762 | 4.1e-14 |
| J96 | respiratorio | INSUFICIENCIA RESPIRATORIA, NO CLASIFICADA EN | 0.718 [0.578, 0.891] | 0.754 | 9.4e-03 |
| J31 | respiratorio | RINITIS, RINOFARINGITIS Y FARINGITIS CRÓNICAS | 0.693 [0.527, 0.911] | 0.753 | 2.5e-02 |
| J98 | respiratorio | OTROS TRASTORNOS RESPIRATORIOS | 0.694 [0.578, 0.832] | 0.734 | 4.5e-04 |
| J22 | respiratorio | INFECCIÓN AGUDA NO ESPECIFICADA DE LAS VÍAS R | 0.719 [0.646, 0.800] | 0.733 | 1.6e-08 |
| J04 | respiratorio | LARINGITIS Y TRAQUEÍTIS AGUDAS | 0.711 [0.635, 0.795] | 0.728 | 2.6e-08 |
| J46 | respiratorio | ESTADO ASMÁTICO | 0.707 [0.625, 0.799] | 0.727 | 2.2e-07 |
| J00 | respiratorio | RINOFARINGITIS AGUDA [RESFRIADO COMÚN] | 0.673 [0.619, 0.732] | 0.688 | 1.0e-18 |
| J20 | respiratorio | BRONQUITIS AGUDA | 0.654 [0.584, 0.733] | 0.682 | 2.3e-12 |
| J21 | respiratorio | BRONQUIOLITIS AGUDA | 0.623 [0.554, 0.700] | 0.659 | 4.1e-14 |

- H frio_12: 14/164 con q < 0.05 (1 suben, 13 bajan); controles Z con q < 0.05: 3/11

### H: códigos con q < 0.05, frio_12

Fuente: `codigos_fdr_2012_2025.csv`

| cie3 | capitulo | nombre | irr | irr_contraido | q |
|---|---|---|---|---|---|
| R69 | sintomas | CAUSAS DE MORBILIDAD DESCONOCIDAS Y NO ESPECI | 1.956 [1.326, 2.884] | 1.376 | 0.017 |
| J00 | respiratorio | RINOFARINGITIS AGUDA [RESFRIADO COMÚN] | 0.807 [0.707, 0.921] | 0.836 | 0.023 |
| J04 | respiratorio | LARINGITIS Y TRAQUEÍTIS AGUDAS | 0.622 [0.465, 0.833] | 0.836 | 0.023 |
| S01 | traumatismos | HERIDA DE LA CABEZA | 0.758 [0.649, 0.886] | 0.811 | 0.014 |
| S81 | traumatismos | HERIDA DE LA PIERNA | 0.604 [0.437, 0.834] | 0.811 | 0.029 |
| T14 | traumatismos | TRAUMATISMO DE REGIONES NO ESPECIFICADAS DEL | 0.713 [0.591, 0.860] | 0.797 | 0.014 |
| U07 | covid | USO EMERGENTE DE U07 | 0.586 [0.434, 0.792] | 0.780 | 0.014 |
| A09 | infecciosas | DIARREA Y GASTROENTERITIS DE PRESUNTO ORIGEN | 0.779 [0.684, 0.888] | 0.778 | 0.014 |
| R50 | sintomas | FIEBRE DE OTRO ORIGEN Y DE ORIGEN DESCONOCIDO | 0.654 [0.520, 0.823] | 0.725 | 0.014 |
| Z48 | Z_control | OTROS CUIDADOS POSTERIORES A LA CIRUGÍA | 0.638 [0.471, 0.864] | 0.718 | 0.043 |
| Z51 | Z_control | OTRA ATENCIÓN MÉDICA | 0.628 [0.475, 0.830] | 0.700 | 0.022 |
| Z04 | Z_control | EXAMEN Y OBSERVACIÓN POR OTRAS RAZONES | 0.551 [0.382, 0.794] | 0.677 | 0.023 |
| A05 | infecciosas | OTRAS INTOXICACIONES ALIMENTARIAS BACTERIANAS | 0.483 [0.333, 0.701] | 0.536 | 0.014 |
| A97 | infecciosas | DENGUE | 0.207 [0.075, 0.570] | 0.508 | 0.029 |

### Controles negativos Z, >= 36

Fuente: `codigos_fdr_2012_2025.csv`

| cie3 | nombre | irr | q |
|---|---|---|---|
| Z71 | PERSONAS EN CONTACTO CON LOS SERVICIOS DE SAL | 1.116 [1.031, 1.209] | 0.020 |
| Z48 | OTROS CUIDADOS POSTERIORES A LA CIRUGÍA | 1.131 [1.025, 1.248] | 0.037 |
| Z33 | ESTADO DE EMBARAZO, INCIDENTAL | 1.362 [1.047, 1.773] | 0.053 |
| Z51 | OTRA ATENCIÓN MÉDICA | 1.131 [0.992, 1.290] | 0.130 |
| Z34 | SUPERVISIÓN DE EMBARAZO NORMAL | 1.025 [0.990, 1.060] | 0.280 |
| Z76 | PERSONAS EN CONTACTO CON LOS SERVICIOS DE SAL | 1.059 [0.955, 1.175] | 0.410 |
| Z32 | EXAMEN Y PRUEBA DEL EMBARAZO | 1.031 [0.976, 1.089] | 0.410 |
| Z39 | EXAMEN Y ATENCIÓN DEL POSTPARTO | 1.070 [0.894, 1.282] | 0.590 |
| Z03 | OBSERVACIÓN Y EVALUACIÓN MÉDICAS POR SOSPECHA | 0.955 [0.799, 1.143] | 0.750 |
| Z04 | EXAMEN Y OBSERVACIÓN POR OTRAS RAZONES | 0.948 [0.694, 1.296] | 0.830 |
| Z35 | SUPERVISIÓN DE EMBARAZO DE ALTO RIESGO | 1.003 [0.936, 1.076] | 0.950 |

- respiratorios (J) que bajan a >= 36 con q < 0.05: 14 de 15

### Heterogeneidad entre códigos dentro del capítulo (tau, log-IRR calor)

Fuente: `codigos_fdr_2012_2025.csv`

| grupo | capitulo | n | tau |
|---|---|---|---|
| endocrinas | endocrinas | 6 | 0.27 |
| circulatorio | circulatorio | 4 | 0.18 |
| infecciosas | infecciosas | 6 | 0.16 |
| genitourinario | genitourinario | 11 | 0.16 |
| sintomas | sintomas | 11 | 0.15 |
| global | sangre | 5 | 0.14 |
| global | ojo | 5 | 0.14 |
| global | perinatal | 5 | 0.14 |
| global | tumores | 5 | 0.14 |
| global | covid | 5 | 0.14 |
| respiratorio | respiratorio | 15 | 0.11 |
| traumatismos | traumatismos | 35 | 0.11 |
| embarazo | embarazo | 20 | 0.06 |
| digestivo | digestivo | 18 | 0.05 |
| oido | oido | 3 | 0.05 |
| mentales | mentales | 4 | 0.03 |
| Z_control | Z_control | 11 | 0.03 |
| nervioso | nervioso | 3 | 0.02 |
| piel | piel | 6 | 0.00 |
| osteomuscular | osteomuscular | 6 | 0.00 |

- H4 D: 62 códigos; mediana M3/M1 0.993; q < 0.05: T63 0.640 [0.537, 0.762] (M1 1.63, M3 1.04, q 3.5e-05)
- H4 E: 59 contrastes; separación numérica: A90 C2; q < 0.05: 0; T63: C1 0.63 [0.41, 0.99] q 0.240; C2 0.77 [0.58, 1.02] q 0.311; C3 0.57 [0.40, 0.81] q 0.120

### I: Tmax vs temperatura aparente (BIC) y seco vs húmedo

Fuente: `humedad_comparacion_2012_2025.csv`

| cap | dbic | mejor | tmax | at | seco | humedo | humedo_vs_seco | q |
|---|---|---|---|---|---|---|---|---|
| traumatismos | -489 | AT | 1.121 | 1.118 | 1.129 [1.107, 1.152] | 1.111 [1.083, 1.141] | 0.984 [0.962, 1.007] | 0.3400 |
| sintomas | -476 | AT | 1.103 | 1.160 | 1.093 [1.063, 1.125] | 1.143 [1.108, 1.179] | 1.045 [1.010, 1.081] | 0.0660 |
| total | -272 | AT | 1.035 | 1.067 | 1.033 [1.016, 1.051] | 1.053 [1.030, 1.077] | 1.019 [1.001, 1.037] | 0.1200 |
| infecciosas | -195 | AT | 1.178 | 1.285 | 1.145 [1.105, 1.186] | 1.266 [1.212, 1.323] | 1.106 [1.053, 1.161] | 0.0008 |
| digestivo | -163 | AT | 1.024 | 1.048 | 1.029 [1.004, 1.054] | 1.032 [0.999, 1.066] | 1.003 [0.975, 1.032] | 0.9400 |
| genitourinario | -160 | AT | 1.140 | 1.162 | 1.154 [1.121, 1.189] | 1.136 [1.099, 1.174] | 0.984 [0.954, 1.015] | 0.4400 |
| piel | -145 | AT | 1.131 | 1.183 | 1.126 [1.085, 1.169] | 1.167 [1.112, 1.225] | 1.036 [0.987, 1.088] | 0.3400 |
| oido | -65 | AT | 1.057 | 1.083 | 1.031 [0.971, 1.095] | 1.129 [1.054, 1.209] | 1.095 [1.020, 1.175] | 0.0660 |
| mentales | -38 | AT | 1.083 | 1.096 | 1.080 [1.042, 1.120] | 1.105 [1.057, 1.155] | 1.023 [0.978, 1.070] | 0.4400 |
| nervioso | -33 | AT | 0.953 | 0.992 | 0.967 [0.925, 1.011] | 0.928 [0.873, 0.987] | 0.960 [0.902, 1.022] | 0.3600 |
| osteomuscular | -15 | AT | 1.019 | 1.060 | 1.007 [0.967, 1.049] | 1.057 [1.010, 1.105] | 1.049 [1.003, 1.096] | 0.1200 |
| sangre | 5 | igual | 1.138 | 1.143 | 1.106 [1.019, 1.201] | 1.201 [1.106, 1.305] | 1.086 [0.983, 1.200] | 0.2800 |
| ojo | 26 | Tmax | 1.093 | 1.101 | 1.096 [1.012, 1.188] | 1.100 [1.015, 1.192] | 1.004 [0.915, 1.101] | 0.9400 |
| circulatorio | 124 | Tmax | 0.895 | 0.935 | 0.898 [0.865, 0.933] | 0.901 [0.865, 0.938] | 1.003 [0.964, 1.042] | 0.9400 |
| endocrinas | 166 | Tmax | 1.155 | 1.106 | 1.164 [1.126, 1.203] | 1.151 [1.103, 1.200] | 0.988 [0.950, 1.029] | 0.7000 |
| respiratorio | 676 | Tmax | 0.779 | 0.831 | 0.773 [0.741, 0.807] | 0.799 [0.757, 0.843] | 1.033 [0.970, 1.100] | 0.4400 |

### I: códigos seco vs húmedo

Fuente: `humedad_codigos_2012_2025.csv`

| cap | humedo | seco | humedo_vs_seco |
|---|---|---|---|
| A09 | 1.204 | 1.130 | 1.066 [1.011, 1.125] |
| A90 | 2.128 | 1.604 | 1.327 [0.830, 2.120] |
| A97 | 2.676 | 1.231 | 2.174 [1.811, 2.611] |
| E86 | 1.996 | 2.152 | 0.928 [0.802, 1.073] |
| N23 | 1.595 | 1.579 | 1.010 [0.913, 1.117] |
| T63 | 1.532 | 1.511 | 1.014 [0.956, 1.075] |

### G: mortalidad por bin (acumulado y mismo día)

Fuente: `rezagos_defunciones_2012_2025.csv`

| cap | [-Inf,12) acumulado_0_14 | [-Inf,12) v0 | [12,15) acumulado_0_14 | [12,15) v0 | [33,36) acumulado_0_14 | [33,36) v0 | [36, Inf) acumulado_0_14 | [36, Inf) v0 |
|---|---|---|---|---|---|---|---|---|
| circulatorio | 1.282 [1.169, 1.406] | 1.018 [0.997, 1.039] | 1.361 [1.272, 1.457] | 1.016 [1.000, 1.032] | 0.930 [0.906, 0.955] | 1.052 [1.043, 1.062] | 1.106 [1.068, 1.145] | 1.116 [1.103, 1.130] |
| endocrino | 1.227 [1.070, 1.407] | 1.019 [0.997, 1.042] | 1.136 [1.048, 1.232] | 0.988 [0.967, 1.008] | 0.928 [0.903, 0.953] | 1.054 [1.041, 1.066] | 1.064 [1.020, 1.110] | 1.109 [1.092, 1.126] |
| externas | 1.050 [0.927, 1.189] | 0.984 [0.931, 1.039] | 1.054 [0.943, 1.179] | 0.959 [0.932, 0.987] | 1.082 [1.042, 1.123] | 1.090 [1.073, 1.106] | 1.166 [1.118, 1.216] | 1.136 [1.113, 1.160] |
| naturales | 1.181 [1.094, 1.275] | 1.006 [0.995, 1.017] | 1.219 [1.163, 1.277] | 0.998 [0.990, 1.005] | 0.952 [0.936, 0.968] | 1.052 [1.047, 1.058] | 1.079 [1.054, 1.105] | 1.099 [1.091, 1.107] |
| renal | 1.408 [1.105, 1.793] | 1.003 [0.941, 1.068] | 1.340 [1.103, 1.628] | 1.004 [0.945, 1.067] | 0.876 [0.813, 0.944] | 1.070 [1.039, 1.102] | 0.977 [0.877, 1.089] | 1.090 [1.045, 1.136] |
| respiratorio | 1.167 [0.977, 1.395] | 1.019 [0.985, 1.054] | 1.403 [1.237, 1.592] | 1.016 [0.988, 1.045] | 0.980 [0.937, 1.025] | 1.055 [1.039, 1.072] | 1.119 [1.057, 1.185] | 1.089 [1.066, 1.113] |
| todas | 1.047 [0.948, 1.157] | 1.002 [0.993, 1.012] | 1.227 [1.177, 1.280] | 0.994 [0.987, 1.001] | 0.960 [0.944, 0.977] | 1.053 [1.048, 1.059] | 1.086 [1.062, 1.110] | 1.098 [1.090, 1.107] |

### G: tamaño de muestra de mortalidad

Fuente: `rezagos_defunciones_2012_2025_resumen.csv`

| cap | n_obs | n_mun | casos |
|---|---|---|---|
| circulatorio | 8574493 | 2457 | 2560925 |
| endocrino | 7253184 | 2457 | 1624604 |
| externas | 5589759 | 2449 | 951076 |
| naturales | 10558539 | 2457 | 8456896 |
| renal | 2534727 | 2394 | 180531 |
| respiratorio | 5600133 | 2454 | 845928 |
| todas | 10669109 | 2457 | 9888888 |

### defunciones_marginacion_2012_2025.csv

Fuente: `defunciones_marginacion_2012_2025.csv`

| fuente | cap | M1 | M2 | M3 | ratio | lo | hi | q |
|---|---|---|---|---|---|---|---|---|
| defunciones | circulatorio | 1.130 | 1.120 | 0.944 | 0.838 | 0.759 | 0.927 | 0.00392 |
| defunciones | endocrino | 1.080 | 1.040 | 0.982 | 0.907 | 0.807 | 1.020 | 0.17500 |
| defunciones | externas | 1.170 | 1.140 | 1.190 | 1.020 | 0.845 | 1.220 | 0.86400 |
| defunciones | naturales | 1.090 | 1.070 | 0.991 | 0.907 | 0.853 | 0.965 | 0.00716 |
| defunciones | renal | 1.020 | 0.838 | 0.838 | 0.822 | 0.574 | 1.180 | 0.39800 |
| defunciones | respiratorio | 1.130 | 1.080 | 1.060 | 0.933 | 0.792 | 1.100 | 0.47700 |
| defunciones | todas | 1.100 | 1.070 | 1.010 | 0.921 | 0.869 | 0.977 | 0.01370 |
| urgencias | circulatorio | 0.892 | 0.916 | 0.888 | 0.995 | 0.895 | 1.110 | 0.94300 |
| urgencias | digestivo | 1.010 | 1.070 | 1.030 | 1.010 | 0.941 | 1.090 | 0.94300 |
| urgencias | endocrinas | 1.170 | 1.160 | 1.080 | 0.923 | 0.832 | 1.020 | 0.40300 |
| urgencias | genitourinario | 1.130 | 1.180 | 1.130 | 0.995 | 0.911 | 1.090 | 0.94300 |
| urgencias | infecciosas | 1.180 | 1.220 | 1.100 | 0.933 | 0.846 | 1.030 | 0.43900 |
| urgencias | mentales | 1.090 | 1.120 | 0.946 | 0.871 | 0.751 | 1.010 | 0.36100 |
| urgencias | nervioso | 0.954 | 1.010 | 0.845 | 0.887 | 0.770 | 1.020 | 0.37000 |
| urgencias | oido | 1.020 | 1.120 | 1.300 | 1.270 | 1.050 | 1.530 | 0.23500 |
| urgencias | ojo | 1.090 | 1.090 | 1.080 | 0.987 | 0.775 | 1.260 | 0.94300 |
| urgencias | osteomuscular | 1.010 | 1.050 | 1.040 | 1.030 | 0.910 | 1.160 | 0.94300 |
| urgencias | piel | 1.130 | 1.200 | 1.050 | 0.932 | 0.811 | 1.070 | 0.64700 |
| urgencias | respiratorio | 0.769 | 0.833 | 0.766 | 0.996 | 0.903 | 1.100 | 0.94300 |
| urgencias | sangre | 1.140 | 1.200 | 0.995 | 0.872 | 0.681 | 1.120 | 0.63700 |
| urgencias | sintomas | 1.090 | 1.140 | 1.190 | 1.090 | 0.999 | 1.200 | 0.36100 |
| urgencias | total | 1.030 | 1.070 | 1.020 | 0.986 | 0.941 | 1.030 | 0.89400 |
| urgencias | traumatismos | 1.120 | 1.150 | 1.090 | 0.975 | 0.924 | 1.030 | 0.64700 |

### defunciones_clima_marg_2012_2025.csv

Fuente: `defunciones_clima_marg_2012_2025.csv`

| cap | clima | bin | M1 | M3 | ratio | lo | hi | q |
|---|---|---|---|---|---|---|---|---|
| circulatorio | 1 | [33,36) | 1.09 | 0.931 | 0.850 | 0.644 | 1.120 | 0.30300 |
| circulatorio | 2 | [36, Inf) | 1.33 | 1.060 | 0.800 | 0.601 | 1.070 | 0.20800 |
| circulatorio | 3 | [36, Inf) | 1.01 | 0.802 | 0.791 | 0.687 | 0.911 | 0.00337 |
| todas | 1 | [33,36) | 1.08 | 0.956 | 0.887 | 0.757 | 1.040 | 0.20800 |
| todas | 2 | [36, Inf) | 1.24 | 1.140 | 0.919 | 0.779 | 1.080 | 0.31600 |
| todas | 3 | [36, Inf) | 1.01 | 0.878 | 0.866 | 0.797 | 0.940 | 0.00337 |

### mortalidad_edad_calidad_2012_2025.csv

Fuente: `mortalidad_edad_calidad_2012_2025.csv`

| parte | cap | M1 | M2 | M3 | ratio | lo | hi | p | q |
|---|---|---|---|---|---|---|---|---|---|
| G (ii) referencia, todos los municipios | circulatorio | 1.13 | 1.12 | 0.944 | 0.838 | 0.759 | 0.927 | 5.60e-04 | NA |
| G (ii) referencia, todos los municipios | todas | 1.10 | 1.07 | 1.010 | 0.921 | 0.869 | 0.977 | 5.88e-03 | NA |
| J-a edad | circulatorio_65mas | 1.14 | 1.12 | 0.932 | 0.816 | 0.732 | 0.910 | 2.62e-04 | 0.000525 |
| J-a edad | circulatorio_menos65 | 1.08 | 1.11 | 1.000 | 0.922 | 0.760 | 1.120 | 4.13e-01 | 0.550000 |
| J-a edad | todas_65mas | 1.12 | 1.09 | 0.962 | 0.861 | 0.801 | 0.925 | 4.62e-05 | 0.000185 |
| J-a edad | todas_menos65 | 1.07 | 1.05 | 1.090 | 1.010 | 0.932 | 1.090 | 8.10e-01 | 0.810000 |
| J-b registro bueno | circulatorio | 1.14 | 1.16 | 0.950 | 0.832 | 0.723 | 0.956 | 9.34e-03 | 0.015900 |
| J-b registro bueno | todas | 1.11 | 1.09 | 1.010 | 0.907 | 0.838 | 0.982 | 1.59e-02 | 0.015900 |

### mortalidad_calidad_terciles_2012_2025.csv

Fuente: `mortalidad_calidad_terciles_2012_2025.csv`

| marg | defunciones | pct_65mas | edad_mediana | municipios | fecha_incompleta_agregado | fecha_incompleta_mediana | tardio_agregado | tardio_mediana | sin_asistencia_agregado | sin_asistencia_mediana | edad_ne_agregado | pct_mun_buena_calidad |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 7400000 | 56.3 | 68 | 819 | 0.0752 | 0.0405 | 1.91 | 1.17 | 11.4 | 12.7 | 0.223 | 60.6 |
| 2 | 1550000 | 60.2 | 71 | 819 | 0.0771 | 0 | 2.55 | 1.71 | 16.3 | 16 | 0.128 | 54.2 |
| 3 | 938000 | 58.9 | 70 | 819 | 0.0881 | 0 | 3.46 | 2.1 | 25.9 | 24.2 | 0.166 | 54.7 |
