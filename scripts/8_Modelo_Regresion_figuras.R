library(lfe)
library(splines)
library(dplyr)
####Crear dataframe para cada uno de los capítulos de enfermedades. 
setwd("Datos/r")
load("casos_años_agrupados_proyecciones.RData")
###Dataframe para datos diarios
ENF_INFECCIOSAS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "CIERTAS ENFERMEDADES INFECCIOSAS Y PARASITARIAS")
ENF_SIST_CIRCULATORIO<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA CIRCULATORIO")
ENF_RESPIRATORIAS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA RESPIRATORIO")
ENF_PIEL<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DE LA PIEL Y DEL TEJIDO SUBCUTANEO" )
ENF_SANGRE<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DE LA SANGRE Y DE LOS ORGANOS HEMATOPOYETICOS, Y CIERTOS TRASTORNOS QUE AFECTAN EL MECANISMO DE LA INMUNIDAD")
ENF_DIGESTIVO<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA DIGESTIVO")
ENF_GENITOURINARIO<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA GENITOURINARIO")
ENF_NERVIO<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA NERVIOSO")
ENF_OSTEOMUSCULAR<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL SISTEMA OSTEOMUSCULAR Y DEL TEJIDO CONJUNTIVO")
ENF_ENDOCRINAS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES ENDOCRINAS, NUTRICIONALES Y METABOLICAS")
ENF_OJOS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DEL OJO Y SUS ANEXOS")
ENF_OIDOS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "ENFERMEDADES DE OIDO Y DE LA APOFISIS MASTOIDES")
ENVENEAMIENTOS<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "TRAUMATISMOS, ENVENENAMIENTOS Y ALGUNAS OTRAS CONSECUENCIAS DE CAUSAS EXTERNAS")
ENF_MENTALES<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "TRASTORNOS MENTALES Y DEL COMPORTAMIENTO")
HALL_ANORMALES<-casos_años_agrupado_Proyecciones%>%
  filter(CAPITULO == "SINTOMAS, SIGNOS Y HALLAZGOS ANORMALES CLINICOS Y DE LABORATORIO, NO CLASIFICADOS EN OTRA PARTE")

#### ajustar nombres de columnas para regresión y modelo de articulo previo

datos_reg<-ENF_ENDOCRINAS### REPETIR PARA CADA CAPÍTULO

datos_reg$rate_adj<- datos_reg$TASA_POR_100milHAB
datos_reg$tmean<- datos_reg$temp_mean
datos_reg$prec<- datos_reg$prcp_avg

datos_reg$statemun<-paste(datos_reg$ENTIDAD,datos_reg$MUNICIPIO, sep = "")
datos_reg$statemonth<-paste(datos_reg$ENTIDAD,datos_reg$month.x, sep = "")
datos_reg$stateday<-paste(datos_reg$ENTIDAD,datos_reg$day, sep = "")

### ASIGNAR ID UNICO PARA CADA MUNICIPIO
MUNICIPIOS<- datos_reg %>%
  distinct(MUNICIPIO, ENTIDAD, .keep_all = TRUE) %>%
  select(MUNICIPIO, ENTIDAD)%>%
  mutate(id= row_number())

ESTADO_AÑO<-datos_reg%>%
  distinct(ENTIDAD, year, .keep_all = TRUE) %>%
  select(ENTIDAD, year)%>%
  mutate(state_year = row_number())

AÑO_DIA<-datos_reg%>%
  distinct(day.x,month.x, year, .keep_all = TRUE) %>%
  select(day.x,month.x, year)%>%
  mutate(day_year = row_number())



#### agregar columnas
datos_reg <- inner_join(datos_reg, MUNICIPIOS, by = c("MUNICIPIO", "ENTIDAD"))
datos_reg <- inner_join(datos_reg, ESTADO_AÑO, by = c("ENTIDAD", "year"))
datos_reg <- inner_join(datos_reg, AÑO_DIA, by = c("day.x","month.x","year"))

datos_reg$state<-datos_reg$ENTIDAD

### agregar promedio de poblacion 

datos_reg <- datos_reg %>%
  group_by(id) %>%
  mutate(popw = mean(pop_tot))


###CORRER REGRESIONES PARA CADA CAPÍTULO DE ENFERMEDADES. eN TOTAL 15 CAPÍTULOS
#Load Mexico data      
      
      data_mex<-as.data.frame(datos_reg)
      data_mex$id<-as.numeric(data_mex$id)
      data_mex$year<-as.numeric(data_mex$year)
      data_mex$month<-as.integer(data_mex$month)
      data_mex$pop_tot<-as.numeric(data_mex$pop_tot)
      str(data_mex)
      ###########################################################
       # run bootstrap.
      ## este se usa para determinar el intervalo de confianza
         cc <- unique(data_mex$id)
         set.seed(1)
         out <- c()
         for (i in 1:1000) {
           tryCatch( { samp <- data.frame(id=sample(cc,length(cc),replace=T))   #use tryCatch() because occasionally weird samples throw an error
               subdata <- inner_join(data_mex,samp)
               #reg <- summary(felm(rate_adj ~ tmax_avg + prec | id + stateday + statemonth + state_year, weights = subdata$popw, data = subdata))$coefficients[c("tmax_avg"),"Estimate"]
               reg <- summary(felm(rate_adj ~ tmean + prec | id + stateday + statemonth + state_year, weights = subdata$popw, data = subdata))$coefficients[c("tmean"),"Estimate"]
               out <- c(out,reg)
           }, error=function(e){})
           print(i)
         }
         #write_csv(data.frame(x = 1:length(out), est = out),path="inputs/bootstrap_runs/BootstrapMainModel_mex.csv")
         ##write.csv(data.frame(x = 1:length(out), est = out),"BootstrapMainModelO_DIANA_mex.csv")
                bootstrapdiana<-data.frame(x = 1:length(out), est = out)

         

### Run alternative specifications ###
        # Mexico
          #data_mex$yearmonth <- data_mex$year*100+data_mex$month
           data_mex$yearmonth <- data_mex$year*100+data_mex$month
           data_mex$yearday<- data_mex$year*1000+data_mex$day_year
           
            xx=5:35
          
          modata_mex1 <- felm(rate_adj ~ tmean + prec | id + stateday + statemonth + state_year | 0 | id , data=data_mex, weights=data_mex$popw)
            yym = data.frame(xx,stateyear=coef(modata_mex1)[1]*xx)
          modata_mex2 <- felm(rate_adj ~ tmean + prec | id + stateday + statemonth + state_year | 0 | id , data=data_mex)  #no weights
            yym = data.frame(yym,noweights=coef(modata_mex2)[1]*xx)
          modata_mex3 <- felm(rate_adj ~ tmean + prec | id + stateday + statemonth + year | 0 | id , data=data_mex, weights=data_mex$popw)  #year FE
            yym = data.frame(yym,year=coef(modata_mex3)[1]*xx)
          modata_mex4 <- felm(rate_adj ~ tmean + prec + as.factor(state)*year | id + stateday + statemonth + year | 0 | id , data=data_mex, weights=data_mex$popw)  #state TT
           yym = data.frame(yym,yearTT=coef(modata_mex4)[1]*xx)
          modata_mex5 <- felm(rate_adj ~ tmean + prec | id + stateday + statemonth + yearmonth | 0 | id , data=data_mex, weights=data_mex$popw)  #year-month
            yym = data.frame(yym,yearmonth=coef(modata_mex5)[1]*xx)
          


### Plot Figure ###
        
      #pdf(file="outputs/raw_figures/Figure1.pdf",height=8,width=10)
            #par(mfrow=c(1,2))
        
        
        # mexico panel
        xx=5:35
        nn <- dim(yym)[2]

        #calculate weighted mean for base rate
        br <- weighted.mean(data_mex$rate_adj,data_mex$popw,na.rm=T)
        
        #read-in bootstrapped runs from above to get CI
        boot<- bootstrapdiana
          est <- as.matrix(boot$est)%*%matrix(xx,ncol=length(xx))
          est <- est - est[,which(xx==20)] 
          ci <- apply(est,2,function(x) quantile(x,probs=c(0.025,0.975)))/br*100
          yyr2 <- yym
          for (i in 2:nn) {
                yyr2[,i] <- (yym[,i] - yym[yym$xx==20,i])/br*100
          }
          
        #plot response curves + ci 
          plot(1,type="n",las=1,ylim=c(-50,50),xlim=c(0,40))
            #polygon(c(xx,rev(xx)),c(ci[1,],rev(ci[2,])),col="lightblue",border = NA)
            lines(xx,yyr2[,2],lwd=2)
        
        abline(h=0,lty=2,col="black",lwd=0.5)
        
        #alternative specs
          clz = c(NA,NA,rep("orange",2),rep("red",2),rep("blue",3))
          lp = c(NA,NA,rep(c(1,2),3),3)
        
            for (i in 3:nn) {
              lines(xx,yyr2[,i],col=clz[i],lty=lp[i],lwd=2)
            }
        
        #plot hist below
            bb = 40
            ht <- hist(data_mex$tmean,breaks=bb,plot=F)
            bb <- length(ht$breaks)  #hist() doesn't follow your exact instructions sometimes...
            rect(ht$breaks[1:(bb-1)],-50,ht$breaks[2:bb],-50+ht$counts/max(ht$counts)*10,col="lightblue")
            
        
        text(35,yyr2[dim(yyr2)[1],2:nn],names(yyr2)[2:nn],pos=4,cex=0.3)
        
    #dev.off()
