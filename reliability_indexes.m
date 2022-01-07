function reliability_indexes()

global dataIN  dataOUT sumatorio_LOEE

X_LOEE=dataOUT.LOEE;    
if dataIN.years==1
    desviacion_LOEE(1)=0;      
    varianza_LOEE(1)=0;      
    coeficiente_LOEE(1)=0;
    media_LOEE(1)=X_LOEE(1);
else
    sumatorio_LOEE=0;
    factor_LOEE=0;
    for i=1:dataIN.years
        sumatorio_LOEE=sumatorio_LOEE+X_LOEE(i);
    end
    media_LOEE(dataIN.years)=sumatorio_LOEE/dataIN.years;
    for i=1:dataIN.years
        factor_LOEE=factor_LOEE+(X_LOEE(i)-media_LOEE(dataIN.years))^2;
    end
    varianza_LOEE(dataIN.years)=factor_LOEE/(dataIN.years*(dataIN.years-1));
    desviacion_LOEE(dataIN.years)=sqrt(varianza_LOEE(dataIN.years));
    coeficiente_LOEE(dataIN.years)=desviacion_LOEE(dataIN.years)/media_LOEE(dataIN.years);
    if (dataIN.years==2)
        coeficiente_LOEE(1)=coeficiente_LOEE(2);
    end
end
dataOUT.trueLOEE(dataIN.years)=media_LOEE(dataIN.years);
dataOUT.coefLOEE(dataIN.years)=coeficiente_LOEE(dataIN.years);


X_LOLE=dataOUT.LOLE;    
if dataIN.years==1
    desviacion_LOLE(1)=0;      
    varianza_LOLE(1)=0;      
    coeficiente_LOLE(1)=0;
    media_LOLE(1)=X_LOLE(1);
else
    sumatorio_LOLE=0;
    factor_LOLE=0;
    for i=1:dataIN.years
        sumatorio_LOLE=sumatorio_LOLE+X_LOLE(i);
    end
    media_LOLE(dataIN.years)=sumatorio_LOLE/dataIN.years;
    for i=1:dataIN.years
        factor_LOLE=factor_LOLE+(X_LOLE(i)-media_LOLE(dataIN.years))^2;
    end
    varianza_LOLE(dataIN.years)=factor_LOLE/(dataIN.years*(dataIN.years-1));
    desviacion_LOLE(dataIN.years)=sqrt(varianza_LOLE(dataIN.years));
    coeficiente_LOLE(dataIN.years)=desviacion_LOLE(dataIN.years)/media_LOLE(dataIN.years);
    if (dataIN.years==2)
        coeficiente_LOLE(1)=coeficiente_LOLE(2);
    end
end
dataOUT.trueLOLE(dataIN.years)=media_LOLE(dataIN.years);
dataOUT.coefLOLE(dataIN.years)=coeficiente_LOLE(dataIN.years);


X_MIOP=dataOUT.MIOP;    
if dataIN.years==1
    desviacion_MIOP(1)=0;      
    varianza_MIOP(1)=0;      
    coeficiente_MIOP(1)=0;
    media_MIOP(1)=X_MIOP(1);
else
    sumatorio_MIOP=0;
    factor_MIOP=0;
    for i=1:dataIN.years
        sumatorio_MIOP=sumatorio_MIOP+X_MIOP(i);
    end
    media_MIOP(dataIN.years)=sumatorio_MIOP/dataIN.years;
    for i=1:dataIN.years
        factor_MIOP=factor_MIOP+(X_MIOP(i)-media_MIOP(dataIN.years))^2;
    end
    varianza_MIOP(dataIN.years)=factor_MIOP/(dataIN.years*(dataIN.years-1));
    desviacion_MIOP(dataIN.years)=sqrt(varianza_MIOP(dataIN.years));
    coeficiente_MIOP(dataIN.years)=desviacion_MIOP(dataIN.years)/media_MIOP(dataIN.years);
    if (dataIN.years==2)
        coeficiente_MIOP(1)=coeficiente_MIOP(2);
    end
end
dataOUT.trueMIOP(dataIN.years)=media_MIOP(dataIN.years);
dataOUT.coefMIOP(dataIN.years)=coeficiente_MIOP(dataIN.years);


X_ILSE=dataOUT.ILSE;    
if dataIN.years==1
    desviacion_ILSE(1)=0;      
    varianza_ILSE(1)=0;      
    coeficiente_ILSE(1)=0;
    media_ILSE(1)=X_ILSE(1);
else
    sumatorio_ILSE=0;
    factor_ILSE=0;
    for i=1:dataIN.years
        sumatorio_ILSE=sumatorio_ILSE+X_ILSE(i);
    end
    media_ILSE(dataIN.years)=sumatorio_ILSE/dataIN.years;
    for i=1:dataIN.years
        factor_ILSE=factor_ILSE+(X_ILSE(i)-media_ILSE(dataIN.years))^2;
    end
    varianza_ILSE(dataIN.years)=factor_ILSE/(dataIN.years*(dataIN.years-1));
    desviacion_ILSE(dataIN.years)=sqrt(varianza_ILSE(dataIN.years));
    coeficiente_ILSE(dataIN.years)=desviacion_ILSE(dataIN.years)/media_ILSE(dataIN.years);
    if (dataIN.years==2)
        coeficiente_ILSE(1)=coeficiente_ILSE(2);
    end
end
dataOUT.trueILSE(dataIN.years)=media_ILSE(dataIN.years);
dataOUT.coefILSE(dataIN.years)=coeficiente_ILSE(dataIN.years);


if (dataIN.years==3)
   dataOUT.coefLOEE(1)=dataOUT.coefLOEE(2);
   dataOUT.coefLOLE(1)=dataOUT.coefLOLE(2);
   dataOUT.coefMIOP(1)=dataOUT.coefMIOP(2);
   dataOUT.coefILSE(1)=dataOUT.coefILSE(2);
end

end