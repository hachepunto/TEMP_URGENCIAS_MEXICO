##### tasa de atención de urgencias en México 
### datos nacionales ajustados a 100.000 habitantes. 
library(data.table)
library(dplyr)
library(stringr)
library(ggplot2)
library(ggalluvial)
library(alluvial)

## abrir archivo de códigos CIE10 y dataframe de atenciones de urgencias
load(file =  "C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/DATOS_URGENCIAS/casos_urgencias_2010_2023.RData")

COD_CIE10<-read.csv("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/CODIGOSCIE10/codigos_cie_10_capitulo_mexico.csv", sep = ",")
COD_CIE10<- subset(COD_CIE10, !duplicated(COD_CIE10))
gc()

### Ahora voy a unir este dataframe con el catálogo de códigos CIE10 para determinar
#### los capítulo a los que pertenece cada DIAGNOSTICO. 
### se realiza el merge con data.table por la cantidad de datos. 

# Convertir dataframes a data.tables
### elimina filas que tienen en blanco el campo de DIAGNOSTICO 
casos_años <- casos_años %>%
  filter(DIAGNOSTICO != "")%>%
  mutate(DIAGNOSTICO = toupper(DIAGNOSTICO))


## PREPARAR EL DATAFRAME DE CODIGOS CIE10
COD_CIE10 <- COD_CIE10 %>%
  select(CLAVE, CAPITULO, NOMBRE)%>%
  unique()

# Realizar el join de dataframes
casos_cie10_cap<-casos_años %>%
  left_join(COD_CIE10, by = c("DIAGNOSTICO" = "CLAVE") )

unique(casos_cie10_cap$AÑO)

#### FILTRAR CAPITULOS NO REQUERIDOS

cap_eliminar <- c(
  "EMBARAZO, PARTO Y PUERPERIO",
  "FACTORES QUE INFLUYEN EN EL ESTADO DE SALUD Y CONTACTO CON LOS SERVICIOS DE SALUD",
  "CIERTAS AFECCIONES ORIGINADAS EN EL PERIODO PERINATAL",
  "TUMORES (NEOPLASIAS)",
  "MALFORMACIONES CONGENITAS, DEFORMIDADES Y ANOMALIAS CROMOSOMICAS",
  "CAUSAS PARA PROPOSITOS ESPECIALES",
  NA
)

casos_cie10_cap<-casos_cie10_cap%>%
  filter(!CAPITULO %in% cap_eliminar)

unique(casos_cie10_cap$CAPITULO)

# Agrupar los datos por la columna nombre.capitulo y contar la frecuencia
casos_cie10_frec <- casos_cie10_cap %>% 
  group_by(AÑO,CAPITULO) %>% 
  summarise(Frec_grupo_DIAGNOSTICO = n())


## eliminar palabra urgencias para dejar solo año. 
casos_cie10_frec$AÑO<- gsub("URGENCIAS_", "", casos_cie10_frec$AÑO )
#casos_cie10_frec<- casos_cie10_frec [,c(2,1,3)]
casos_cie10_frec$AÑO<-as.numeric(casos_cie10_frec$AÑO)
casos_cie10_frec<- as.data.frame(casos_cie10_frec)
str(casos_cie10_frec)
rm(casos_años)
##### abrir tabla de proyecciones poblacionales por año. 

PROYECCIONES_POBLACION<-read.csv("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/PROYECCIONES_POBLACION_MEXICO/pob_mit_proyecciones.csv")
poblacion_anual<-PROYECCIONES_POBLACION %>%
  group_by(AÑO,ENTIDAD)%>%
  summarise(poblacion_anual = sum(POBLACION))%>%
  filter(ENTIDAD == "República Mexicana")

casos_cie10_frec_ajustada<-merge(casos_cie10_frec, poblacion_anual, by = "AÑO")
casos_cie10_frec_ajustada$Tasa_urg_cienmil_hab<- casos_cie10_frec_ajustada$Frec_grupo_DIAGNOSTICO/casos_cie10_frec_ajustada$poblacion_anual*100000
options(scipen = 999)
casos_cie10_frec_ajustada$Tasa_urg_cienmil_hab <- round(casos_cie10_frec_ajustada$Tasa_urg_cienmil_hab, 3)

save(casos_cie10_frec_ajustada, file = "casos_cie10_frec_adj.RData")
rm(list = ls())

### GRAFICAR ALLUVIAL PLOT

library(dplyr)
library(alluvial)

setwd("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/DATOS_LIMPIOS")
load("casos_cie10_frec_adj.RData")


#### dataframe para alluvial

casos_alluvial<-casos_cie10_frec_ajustada %>%
  select(CAPITULO, AÑO, Tasa_urg_cienmil_hab)

### ajustar nombres de capitulos para alluvial

casos_alluvial<-casos_alluvial %>%
  mutate(CAPITULO = ifelse(CAPITULO %in% "CIERTAS ENFERMEDADES INFECCIOSAS Y PARASITARIAS","INFECCIONES Y PARASITOSIS", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DE LA PIEL Y DEL TEJIDO SUBCUTANEO", "ENF. PIEL", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DE LA SANGRE Y DE LOS ORGANOS HEMATOPOYETICOS, Y CIERTOS TRASTORNOS QUE AFECTAN EL MECANISMO DE LA INMUNIDAD", "ENF. SANGRE E INMUNIDAD", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DE OIDO Y DE LA APOFISIS MASTOIDES", "ENF. OIDOS", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL OJO Y SUS ANEXOS", "ENF. OJOS", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA CIRCULATORIO", "ENF. SIST. CIRCULATORIO", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA DIGESTIVO", "ENF. SIST. DIGESTIVO", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA GENITOURINARIO", "ENF. SIST. GENITOURINARIO", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA NERVIOSO", "ENF. SIST.NERVIOSO", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA OSTEOMUSCULAR Y DEL TEJIDO CONJUNTIVO", "ENF. OSTEOMUSCULARES", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES DEL SISTEMA RESPIRATORIO", "ENF. SIST. RESPIRATORIO", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"ENFERMEDADES ENDOCRINAS, NUTRICIONALES Y METABOLICAS", "ENF. ENDOCRINAS", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"SINTOMAS, SIGNOS Y HALLAZGOS ANORMALES CLINICOS Y DE LABORATORIO, NO CLASIFICADOS EN OTRA PARTE", "HALLAZGOS ANORMALES", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"TRASTORNOS MENTALES Y DEL COMPORTAMIENTO", "T. MENTALES", CAPITULO))%>%
  mutate(CAPITULO = ifelse(CAPITULO %in%"TRAUMATISMOS, ENVENENAMIENTOS Y ALGUNAS OTRAS CONSECUENCIAS DE CAUSAS EXTERNAS", "TRAUMATISMOS Y ENVENENAMIENTOS", CAPITULO))



set.seed(100)
cols <- hsv(h = sample(1:15/15), s = sample(3:12)/15, v = sample(3:12)/15)

pdf()
alluvial_ts(casos_alluvial, wave = .2, ygap = 10, col = cols, plotdir = "centred", alpha=.9,
            grid = TRUE, grid.lwd = 5, xmargin = 0.8, lab.cex = .5, xlab = '',
            ylab = '', border = NA, axis.cex = .8, leg.cex = .7,
            leg.col='white', 
            title = "Atención de urgencias en México 2010 a 2023- Tasa *100000 habitantes")



