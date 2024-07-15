library(dplyr)
library(purrr)

# Función para cargar y procesar archivos RDS
cargar_archivos <- function(tipo, directorio, año_inicio, año_fin) {
  lista_datos <- map(año_inicio:año_fin, function(año) {
    nombre_archivo <- sprintf("daymet_v4_daily_na_%s_%d.rds", tipo, año)
    ruta_archivo <- file.path(directorio, nombre_archivo)
    readRDS(ruta_archivo)
  })
  
  datos <- do.call(rbind, lista_datos)
  datos$fecha <- as.Date(paste(datos$year, datos$month, datos$day, sep = "-"))
  
  
  datos
}

# Directorio donde se encuentran los archivos
directorio <- "C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/daymet_temperaturas_municipales_mexico/day_results"

# Año de inicio y fin
año_inicio <- 2010
año_fin <- 2023

# Cargar y procesar los datos
tmin_2010_2023 <- cargar_archivos("tmin", directorio, año_inicio, año_fin)
tmax_2010_2023 <- cargar_archivos("tmax", directorio, año_inicio, año_fin)
prcp_2010_2023 <- cargar_archivos("prcp", directorio, año_inicio, año_fin)

# Unir los dataframes en uno solo
temp_2010_2023 <- tmin_2010_2023 %>%
  left_join(tmax_2010_2023, by = c("state", "municipio", "fecha")) %>%
  left_join(prcp_2010_2023, by = c("state", "municipio", "fecha")) %>%
  mutate(temp_mean = (tmin_avg + tmax_avg) / 2)%>%
  select(municipio, state, fecha, tmin_avg, tmax_avg, prcp_avg, temp_mean,month.x, day.x, year.x)


# Guardar el resultado
save(temp_2010_2023, file = "temp_2010_2023.RData")

