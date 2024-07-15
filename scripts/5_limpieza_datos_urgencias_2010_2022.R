library(data.table)
library(dplyr)
library(stringr)

#### Ubicar la carpeta de trabajo con datos de urgencias 2008 a 2023 descargados de http://www.dgis.salud.gob.mx/contenidos/basesdedatos/da_urgencias_gobmx.html. 
setwd("Datos/Urgencias/")

# Obtener la lista de archivos en la carpeta
archivos <- list.files(full.names = TRUE)

# Crear una lista vacía para almacenar los datos de los archivos
lista_urgencias <- list()

# Recorrer los archivos en la carpeta y abrirlos( cada archivo tiene separador diferente extensión diferente)

for (archivo in archivos) {
  # Leer el archivo y almacenar los datos en la lista
  if (grepl("\\.csv$", archivo)) {
    datos <- read.csv(archivo, sep = ",")
    if (ncol(datos) == 1) {
      datos <- read.csv(archivo, sep = ";")
    }
    if (ncol(datos) == 1) {
      datos <- read.csv(archivo, sep = "|")
    }
  } else if (grepl("\\.txt$", archivo)) {
    datos <- read.delim(archivo, sep = "|")
  } else if (grepl("\\.CSV$", archivo)) {
    datos <- read.delim(archivo, sep = ",")
  } else {
    print(paste("Formato de archivo no compatible:", archivo))
    next
  }
  
  # Obtener el nombre de cada dataframe pero  sin la extensión del archivo
  nombre_objeto <- gsub("\\..*", "", archivo)
  
  
  lista_urgencias[[archivo]] <- datos
}


### generar a partir de cada dataframe de la lista, un objeto


for (i in seq_along(lista_urgencias)) {
  # Obtener el nombre
  nombre_objeto <- gsub("^\\./|\\.csv|.CSV|.txt*$", "", archivos[i])
  
  # Extraer el dataframe de la lista
  dataframe <- lista_urgencias[[i]]
  
  # Agregar la nueva columna con el nombre de cada dataframe
  dataframe$nombre_de_objeto <- nombre_objeto
  
  # Asignar el dataframe como un objeto individual
  assign(nombre_objeto, dataframe)
  
}


###Renombrar colnames para generar nuevo dataframe único

URGENCIAS_2010$FECHAINGRESO<-URGENCIAS_2010$FECHAINGRE
URGENCIAS_2011$FECHAINGRESO<-URGENCIAS_2011$FECHAINGRE
URGENCIAS_2012$FECHAINGRESO<-URGENCIAS_2012$FECHAINGRE
URGENCIAS_2013$FECHAINGRESO<-URGENCIAS_2013$FECHAINGRE
URGENCIAS_2014$FECHAINGRESO<-URGENCIAS_2014$FECHAINGRE
URGENCIAS_2020$FECHAINGRESO<-URGENCIAS_2020$fechaingreso
URGENCIAS_2022$FECHAINGRESO<-URGENCIAS_2022$fechaingreso
URGENCIAS_2023$FECHAINGRESO<-URGENCIAS_2023$fechaingreso

###### Creación de dataframes unicamente con los datos de diagnósticos y año para posteriormente hacer el grafico aluvial 

# Crear una lista para almacenar los data frames
casos_años <- list()

# Nombres de los data frames originales
nombres_originales <- ls(pattern = "URGENCIAS_\\d{4}")

# Bucle para crear los nuevos data frames
for (nombre in nombres_originales) {
  # Obtener el año del nombre original
  año <- str_extract(nombre, "\\d{4}")
  
  # Extraer las columnas deseadas del data frame original
  df <- get(nombre) %>% 
    select(nombre_de_objeto,MES_ESTADISTICO, AFECPRIN, ENTRESIDENCIA, CLUES, FECHAINGRESO, EDAD, CVEEDAD, SEXO ) %>% 
    rename(DIAGNOSTICO = AFECPRIN, AÑO = nombre_de_objeto)
  
  # Asignar el nuevo data frame a la lista
  casos_años[[año]] <- df
}


# Combinar los data frames en uno solo con el Diagnóstico y año. Preparando los datos para el grafico alluvial
casos_años <- bind_rows(casos_años)

save(casos_años, file =  "r/urgencias/casos_urgencias_2010_2023.RData")
