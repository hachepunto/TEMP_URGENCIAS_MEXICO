#### analisis geolocalizacion y temperaturas máximas méxico


##limpiar entorno de trabajo
rm(list = ls())
gc()


### abrir e instalar paquetes necesarios

if (!require("pacman")) install.packages("pacman")

pacman::p_load(raster, sf, data.table, tidyverse, maps, janitor, 
               tictoc, future, future.apply, beepr, ncdf4)

### paralelizar los procesos 

plan(multisession)


### abrir archivo de localización de municipios. Este es un archivo shp que contiene los límites geográficos de México

mx_mun = st_read("datos/municipios/mex_admbnda_adm2_govmex_20210618.shp") %>%
  mutate(municipio = ADM2_ES,
         state     = ADM1_ES) %>%
  dplyr::select(municipio, state)

plot(mx_mun)

### abrir archivos de datos de temperaturas máximas de Daymet

tmax_na_2008_daily <-"C:/Users/DEALVAREZ/Documents/2023/PROYECTOS/PROYECTOS/DATOS_SALUD_URGENCIAS_MEXICO/PROYECTO/DATOS/TEMPERATURA_MEXICO_MUNICIPAL_NASA/diaria_daymet/daymet_v4_daily_na_tmax_2023.nc" %>%
  raster::stack()


plot(tmax_na_2008_daily)

### el CRS de tmax_na_2008. chat gpt me dice que si los datos no tienen un datum especificado, podría ser difícil o incluso imposible combinarlos con otros conjuntos de datos que utilizan diferentes datums

crs(tmax_na_2008_daily)

### ahora voy a agregar el datum

crs(tmax_na_2008_daily) <- "+proj=lcc +lat_0=42.5 +lon_0=-100 +lat_1=25 +lat_2=60 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

### ahora se debe cambiar el CRS DE mx_mun para que puedan unirse los datos correctamente

mx_mun<- mx_mun %>%
  st_transform(crs = st_crs(tmax_na_2008_daily))

## ver los datos CRS
st_crs(mx_mun)


### recortar para tener únicamente los datos de México

tmax_na_2008_daily_crop<-raster::crop(x = tmax_na_2008_daily,
                                y = mx_mun)

tmax_mun_2008_daily <- raster::mask(x = tmax_na_2008_daily_crop,
                              mask = mx_mun)

## ahora dibujo los mapas de temperatura máxima mensual para el año analizado ( el rango es desde el 2008 al 2023)
pdf("temperatura_mexico_plot_diario.pdf")
plot(tmax_mun_2008_daily)
dev.off()

### ahora extraigo los datos a un dataframe

tmax_mun_extract_daily<- raster::extract(
  x = tmax_mun_2008_daily, ## valores de temperatura máxima
  y = mx_mun, ## ubicaciones de los municipios
  fun = mean, ##calcular el valor promedio de las temperaturas máximas de cada municipio
  na.rm = T, ##eliminar NA antes de calcular la estadística
  sp = T) ## el resultado es un objeto espacial


#### dataframe para temperatura máxima mensual promedio para cada municipio

tmax_mun_extract_daily =  tmax_mun_extract_daily %>%
  st_as_sf() %>%  ## convierto el objeto espacial a objeto sf (simple features)
  st_drop_geometry() ## se elimina información geométrica de los datos y solo se va a mantener datos de temperatura máxima


### generar dataframe con datos de temperatura máxima para cada mes por municipio
### long format


tmax_mun_extract_daily_long = pivot_longer(tmax_mun_extract_daily,
                                           cols = starts_with(paste0("X","2023")),
                                           names_to  = c("month","day"), 
                                           names_pattern = "X2023.(\\d+)\\.(\\d+)",
                                           values_to = "tmax_avg") %>%
                                            mutate(month = as.numeric(month),
                                                   day = as.numeric(day),
                                                   year = 2023)


save.image("daymet_v4_daily_na_tmax_2023.rds")
