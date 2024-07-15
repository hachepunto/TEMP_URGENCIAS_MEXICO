### DATOS DE URGENCIAS Y DIAGNOSTICOS SEGÚN CODIGO CIE10
### EN ESTE SCRIPT GENERO DATAFRAME CON DATOS DE CADA DIAGÓSTICO POR CADA MUNICIPIO. 

###librerias
library(data.table)
library(dplyr)
library(stringr)
library(stringi)
library(ggplot2)
library(plot3D)
library(plot3Drgl)
library(lubridate)

## paquetes para regresión
library(lfe)
library(splines)

#setwd("~/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/DATOS_LIMPIOS")
### abrir archivos de urgencias
load(file =  "C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/DATOS_LIMPIOS/casos_urgencias_2010_2023.RData")

### FILTRAR DATOS EN BLANCO
casos_años <- casos_años %>%
  filter(DIAGNOSTICO != "", FECHAINGRESO != "") %>%
  as.data.table() %>%
  mutate(DIAGNOSTICO = toupper(DIAGNOSTICO))

gc()

## abrir archivo de códigos CIE10
CODIGOS_CIE10<-read.csv("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/CODIGOSCIE10/codigos_cie_10_capitulo_mexico.csv", sep = ",")
CODIGOS_CIE10<- subset(CODIGOS_CIE10, !duplicated(CODIGOS_CIE10))
CODIGOS_CIE10 <- as.data.table(CODIGOS_CIE10)
unique(CODIGOS_CIE10$CAPITULO)

#### filtrar códigos cie-10 para facilitar el estudio 
#### se excluyen: Causas para propósitos especiales
##### ciertas afecciones originadas en el periodo prenatal
### embarazo parto y puerperio
###factores que influyen en el estado de salud y contracto con servicios de salud
##### malformaciones congénitas
#### signos y síntomas anormales no clasificados
###tumores

Capitulos_a_filtrar<- c(
  "EMBARAZO, PARTO Y PUERPERIO",
  "FACTORES QUE INFLUYEN EN EL ESTADO DE SALUD Y CONTACTO CON LOS SERVICIOS DE SALUD",
  "CIERTAS AFECCIONES ORIGINADAS EN EL PERIODO PERINATAL",
  "TUMORES (NEOPLASIAS)",
  "MALFORMACIONES CONGENITAS, DEFORMIDADES Y ANOMALIAS CROMOSOMICAS",
  "CAUSAS PARA PROPOSITOS ESPECIALES",
  "",
  NA
)

CODIGOS_CIE10<-CODIGOS_CIE10%>%
  filter(!CAPITULO %in% Capitulos_a_filtrar)

unique(CODIGOS_CIE10$CAPITULO)


CODIGOS_CIE10<-CODIGOS_CIE10%>%
  select(CLAVE, CAPITULO)

unique(CODIGOS_CIE10$CAPITULO)


#### CON ESTOS DATOS, SE DEBE GENERAR UN DATAFRAME QUE CONTENGA LA INFORMACIÓN DE MUNICIPIO, DATOS DE URGENCIAS POR CADA GRUPO DE DIAGNOSTICO, 
##### TEMPERATURA DIARIA Y TEMPERATURA MENSUAL PARA CADA MUNICIPIO
#### PRIMERO HACER EL CALCULO DE FRECUENCIAS DE CASOS DE URGENCIAS PARA CADA GRUPO DE DX POR DIA

casos_años<-casos_años%>%
  left_join(CODIGOS_CIE10, by = c("DIAGNOSTICO" = "CLAVE"))

casos_años<-casos_años%>%
  filter(!is.na(CAPITULO))

#unique(casos_años$CAPITULO)

### abrir dataframe de clues y municipios
CAT_CLUES<-read.csv("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/CLUES/CATCLUES_2023_actualizado.csv")
CAT_CLUES <- as.data.table(CAT_CLUES)

### se agrega el dato de CLUES
CAT_CLUES<-CAT_CLUES %>%
  select(CLUES, CLAVE.DE.LA.ENTIDAD, ENTIDAD, CLAVE.DEL.MUNICIPIO, MUNICIPIO)

###agregar nombre de la entidad y municipio al dataframe de casos de urgencias


casos_años<-casos_años%>%
  left_join(CAT_CLUES, by = "CLUES")

### Agrupar los casos por capitulo
#### primero convierto al mismo formato de fecha aquellas lineas que fueron llenadas por la insitucion mal
#casos_años$FECHAINGRESO<- as_date(casos_años$FECHAINGRESO)
no_hacen_match<-casos_años[is.na(as.Date(casos_años$FECHAINGRESO)),]
no_hacen_match$FECHAINGRESO<-sub(" 201$", " 2019", no_hacen_match$FECHAINGRESO)

# Función para convertir nombres de meses a números
convertir_mes_a_numero <- function(fecha) {
  meses <- c("Jan"="01", "Feb"="02", "Mar"="03", "Apr"="04", "May"="05", "Jun"="06", 
             "Jul"="07", "Aug"="08", "Sep"="09", "Oct"="10", "Nov"="11", "Dec"="12")
  
  # Reemplazar el nombre del mes por su número correspondiente
  for (mes in names(meses)) {
    fecha <- gsub(mes, meses[mes], fecha)
  }
  
  return(fecha)
}


# Aplicar la función a la columna de fechas y limpiar espacios dobles
no_hacen_match$FECHAINGRESO <- sapply(no_hacen_match$FECHAINGRESO, function(fecha) {
  fecha_numerica <- convertir_mes_a_numero(fecha)
  gsub("  ", " ", fecha_numerica) # Eliminar dobles espacios
})

# Convertir la columna a formato de fecha
no_hacen_match$FECHAINGRESO <- as.Date(no_hacen_match$FECHAINGRESO, format="%m %d %Y")
casos_años<-casos_años[!is.na(as.Date(casos_años$FECHAINGRESO)),]
casos_años$FECHAINGRESO<-as.Date(casos_años$FECHAINGRESO)
casos_años<-rbind(casos_años, no_hacen_match)

#unique(casos_años$FECHAINGRESO)

#### Agrupar cada capítulo, por fecha y municipio. 

casos_años_agrupado<- casos_años%>%
  group_by(CLAVE.DE.LA.ENTIDAD, ENTIDAD , CLAVE.DEL.MUNICIPIO, MUNICIPIO, CAPITULO , FECHAINGRESO)%>%
  summarise(numero_de_casos = n())
#head(casos_años_agrupado)
rm( CAT_CLUES, CODIGOS_CIE10, casos_años)
gc()

###A ESTE DTAFRAME AGREGO LOS DATOS DE TEMPERATURAS DIARIAS PARA CADA MUNICIPIO DURANTE ESTE PERIODO DE TIEMPO
#### abrir archivos de datos de temperatura
### ABIR DATOS DE TEMPERATURAS
load("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/daymet_temperaturas_municipales_mexico/day_results/temp_2010_2023.RData")
####EN ESTE ARCHIVO CUENTO CON NOMBRESDE MUNICIPIOS Y ESTADOS PERO NO CON LOS CODIGOS

temp_2010_2023_a<-temp_2010_2023%>%
  mutate(state = toupper(state)) %>%
  mutate(municipio = toupper(municipio)) %>%
  mutate(NOM_ENT = iconv(state, "UTF-8", "ASCII//TRANSLIT")) %>%
  mutate(MUN = iconv(municipio, "UTF-8", "ASCII//TRANSLIT")) %>%
  mutate(NOM_ENT = gsub("DISTRITO FEDERAL","CIUDAD DE MEXICO",NOM_ENT )) %>%
  mutate(NOM_ENT = gsub("QUERETARO DE ARTEAGA","QUERETARO" ,NOM_ENT )) %>%
  mutate(MUN = gsub("CINTALAPA","CINTALAPA DE FIGUEROA" ,MUN ))%>%
  mutate(MUN = gsub("JONACATEPEC","JONACATEPEC DE LEANDRO VALLE" ,MUN ))%>%
  mutate(MUN = gsub("HEROICA CIUDAD DE JUCHITAN DE ZARAGOZA","JUCHITAN DE ZARAGOZA" ,MUN ))%>%
  mutate(MUN = gsub("VILLA DE TUTUTEPEC DE MELCHOR OCAMPO","VILLA DE TUTUTEPEC" ,MUN ))%>%
  mutate(MUN = gsub("JONACATEPEC","JONACATEPEC DE LEANDRO VALLE" ,MUN ))%>%
  mutate(MUN = ifelse(NOM_ENT == "SAN LUIS POTOSI", gsub("AHUALULCO","AHUALULCO DEL SONIDO 13" ,MUN), MUN))


casos_años_agrupado<-casos_años_agrupado%>%
  mutate(MUNICIPIO = iconv(MUNICIPIO, "UTF-8", "ASCII//TRANSLIT"))



rm(temp_2010_2023)  
rm(no_hacen_match)

casos_años_agrupado<-as.data.table(casos_años_agrupado)
temp_2010_2023_a<-as.data.table(temp_2010_2023_a)


#### UNIR CASOS CON TEMPERATURA
casos_años_agrupado_temp<-casos_años_agrupado %>%
  inner_join(temp_2010_2023_a, by = c("ENTIDAD"="NOM_ENT" , "MUNICIPIO"= "MUN", "FECHAINGRESO"="fecha"))
rm(temp_2010_2023_a)
rm(casos_años_agrupado)


### Abrir dataframes de proyecciones de municipios
PROYECCIONES_POBLACION_MUNICIPIO<-read.csv("C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/PROYECCIONES_POBLACION_MEXICO/proy_pob_mpo_agregados_2010-2030.csv")
PROYECCIONES_POBLACION_MUNICIPIO <- PROYECCIONES_POBLACION_MUNICIPIO %>%
  mutate(edo = toupper(edo)) %>%
  mutate(mpo = toupper(mpo)) %>%
  mutate(edo = iconv(edo, "UTF-8", "ASCII//TRANSLIT")) %>%
  mutate(mpo = iconv(mpo, "UTF-8", "ASCII//TRANSLIT"))%>%
  mutate(edo = gsub("BAJACALIFORNIA","BAJA CALIFORNIA",edo))%>%
  mutate(edo = gsub("BAJACALIFORNIASUR","BAJA CALIFORNIA SUR",edo))%>%
  mutate(edo = gsub("COAHUILA","COAHUILA DE ZARAGOZA",edo))%>%
  mutate(edo = gsub("DISTRITOFEDERAL","CIUDAD DE MEXICO",edo))%>%
  mutate(edo = gsub("MICHOACAN","MICHOACAN DE OCAMPO",edo))%>%
  mutate(edo = gsub("NUEVOLEON","NUEVO LEON",edo))%>%
  mutate(edo = gsub("QUINTANAROO","QUINTANA ROO",edo))%>%
  mutate(edo = gsub("SANLUISPOTOSI","SAN LUIS POTOSI",edo))%>%
  mutate(edo = gsub("VERACRUZ","VERACRUZ DE IGNACIO DE LA LLAVE",edo))%>%
  mutate(mpo = gsub("CINTALAPA", "CINTALAPA DE FIGUEROA",mpo))%>%
  mutate(mpo = gsub("SILAO","SILAO DE LA VICTORIA",mpo))%>%
  mutate(mpo = gsub("TLAQUEPAQUE","SAN PEDRO TLAQUEPAQUE",mpo))%>%
  mutate(mpo = gsub("ACAMBAY","ACAMBAY DE RUIZ CASTANEDA",mpo))%>%
  mutate(mpo = gsub("DR. ARROYO","DOCTOR ARROYO",mpo))%>%
  mutate(mpo = gsub("GRAL. ESCOBEDO","GENERAL ESCOBEDO",mpo))%>%
  mutate(mpo = gsub("HEROICA CIUDAD DE JUCHITAN DE ZARAGOZA", "JUCHITAN DE ZARAGOZA",mpo))%>%
  mutate(mpo = gsub("VILLA DE TUTUTEPEC DE MELCHOR OCAMPO","VILLA DE TUTUTEPEC",mpo))%>%
  mutate(mpo = ifelse(edo == "SAN LUIS POTOSI",gsub("AHUALULCO","AHUALULCO DEL SONIDO 13",mpo), mpo))

### unir los dos dataframes de casos años y de proyecciones de población
casos_años_agrupado_temp$year<-as.integer(casos_años_agrupado_temp$year)
casos_años_agrupado_Proyecciones<-casos_años_agrupado_temp%>%
  as.data.table()%>%
  inner_join(PROYECCIONES_POBLACION_MUNICIPIO, by = c("ENTIDAD"= "edo","MUNICIPIO" = "mpo", "year"="año") )

### calcular la tasa de casos de urgencias x 100.000 habitantes
casos_años_agrupado_Proyecciones<-casos_años_agrupado_Proyecciones%>%
  select(CLAVE.DE.LA.ENTIDAD, ENTIDAD, CLAVE.DEL.MUNICIPIO, MUNICIPIO, FECHAINGRESO,year, month.x, day.x, CAPITULO,numero_de_casos, pop_tot, temp_mean, tmax_avg, tmin_avg, prcp_avg)
rm(casos_años_agrupado_temp)
head(casos_años_agrupado_Proyecciones)
unique(casos_años_agrupado_Proyecciones$CAPITULO)

casos_años_agrupado_Proyecciones<- casos_años_agrupado_Proyecciones %>%
  mutate(TASA_POR_100milHAB = numero_de_casos / pop_tot *100000)%>%
  filter(!is.na(TASA_POR_100milHAB))

#save(casos_años_agrupado_Proyecciones, file = "casos_años_agrupados_proyecciones.RData")
