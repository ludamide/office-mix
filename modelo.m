function modelo

clear all
clc

global dataIN  dataOUT

%% Cargando datos de entrada a través de archivos CSV
dataIN.genConfig = load('genConfig.csv');
dataIN.demand = load('demand.csv');
dataIN.battery = load('battery.csv');
dataIN.convergence = load('convergence.csv');
dataIN.holiday = load('holiday.csv');

%% Cargando datos de entrada por ventana de comandos
dataIN.latitud = input('Introducir latitud del emplazamiento: ');
while ((dataIN.latitud < -90)||(dataIN.latitud > 90));    
    disp('Introduzca un valor entero entre -90 y 90.');
    dataIN.latitud = input('Introducir latitud del emplazamiento: ');
end
oc_pro = input('Introducir perfil de ocupación: ');
while ((oc_pro ~= 1)&&(oc_pro ~= 2))
    disp('Introduzca un valor entero entre 1 y 2');
    oc_pro = input('Introducir perfil de ocupación: ');
end

%% 
[genCount,~]=size(dataIN.genConfig);


dataIN.years = 0;
var = 0;
lat=dataIN.latitud;                                           % Site latitude
genData.Pwind_total=zeros(1,8760);
genData.Ppv_total=zeros(1,8760);
genData.Pfuel_total=zeros(1,8760);
genData.Pgas_total=zeros(1,8760);
genData.Pothers_total=zeros(1,8760);

% Variables needed to init other variables in the loop

en_wtg = 0;
en_pv = 0;
en_fuel = 0;
en_gas = 0;
en_others = 0;
en_bat=0;

dataOUT.Pgen_avg = zeros(1,8760);
wind_ic = 0;
wind_oc = 0;   
pv_ic = 0;
pv_oc = 0;   
fuel_ic = 0;
fuel_oc = 0;    
gas_ic = 0;
gas_oc = 0;
other_ic = 0;
other_oc = 0;

% DATA FOR SIMULATION/////////////////////////////////////////////////////
%% PV GENERATION DATA
% Correlation constants for model
%               A       B       C      D        E        F
correl_const = [1.259   73.51   1175   0.785    0.3313   51.03             % January
                1.117   65.99   1382   0.8464   0.3061   71.55             % February
                1.003   79.68   1636   0.9669   0.2900   64.18             % March
                0.889   105.7   1810   1.1050   0.3030   88.40             % April
                0.9142  80.38   1777   1.1740   0.3579   98.47             % May
                0.9113  29.84   1038   1.1560   0.7719   84.1              % June
                1.407   50.2    602    1.1190   1.4670   73.19             % July
                0.9036  31.19   531    1.0230   1.6480   56.72             % August
                0.9618  42.15   816    0.9955   0.9439   55.21             % September
                1.069   56.60   1103   0.9955   0.4878   48.69             % October
                1.176   60.29   1370   0.8599   0.2748   57.16             % November
                1.186   70.85   1189   0.7876   0.3405   49.92];           % December            

% probability matrix
Pd = [ 0.80  0.19  0.01                                                       
       0.36  0.58  0.06
       0.16  0.67  0.17];

day = 1:1:365;      
chain_length = 365;
Ta = temperature + 5;                                                 % Data taken from another function

% VECTOR DE CONSUMOS (medido en kWh)

consumption=[ 11.04     % tomas de uso general (3 tomas de 16A / 230V)
              0.077     % PC + equipo informático (una impresora + escáner por cada 5 PCs, 10 minutos de uso por hora)
              0.167     % appliances oficinas (10 minutos de uso por hora)
              0.283 ];  % ascensores (5 minutos de uso por hora)
                
% VECTOR DE LUMINARIAS (medido en lm/W)

luminary=[ 15       % incandescente
           20       % halógena
           60       % fluorescente / LED
           87       % haluro metálico
           117      % vapor de sodio ALTA presión
           150      % vapor de sodio BAJA presión
           50  ];   % vapor de mercurio
             
%% DEMAND MODEL DATA

r_type = dataIN.demand(:,1);      % tipo de sala (0 -> reuniones; 1 -> oficina)
in_param = dataIN.demand(:,2);    % parámetro de entrada (reuniones -> superficie en m^2; oficina -> nº de PCs)
l_type = dataIN.demand(:,3);      % tipo de luminaria

dataIN.roomCount=size(dataIN.demand,1);

% Superficie total del edificio
surface=zeros(1,dataIN.roomCount);
for m=1:dataIN.roomCount
    
    if (r_type(m)==1)
        
        surface(m)=4*in_param(m);        
    else surface(m)=in_param(m);
        
    end    
end
surf=sum(surface); 

% Uso de cargas según perfil de ocupación

%      8-15/8-13,15-18  #Horas/día
hours=[ 2       4       %tomas de uso general
        7       8       %PC + equipo informático (toda la jornada)
        1       2       %appliances oficinas
        2       4       %ascensores
        7       8 ];    %aire acondicionado (toda la jornada)

% Perfil de luminarias

light_pro=[  0        0         % 1
             0        0         % 2
             0        0         % 3
             0        0         % 4
             0        0         % 5
             0        0         % 6
             0        0         % 7
            0.20     0.17       % 8
            0.18     0.15       % 9
            0.15     0.14       % 10
            0.13     0.11       % 11
            0.12     0.10       % 12
            0.11      0         % 13
            0.11      0         % 14
             0       0.11       % 15
             0       0.11       % 16
             0       0.11       % 17
             0        0         % 18
             0        0         % 19
             0        0         % 20
             0        0         % 21
             0        0         % 22
             0        0         % 23
             0        0    ];   % 24
         
% Perfil de tomas de uso general

plug_pro=[   0        0         % 1
             0        0         % 2
             0        0         % 3
             0        0         % 4
             0        0         % 5
             0        0         % 6
             0        0         % 7
            0.20     0.20       % 8
            0.18     0.16       % 9
            0.09     0.05       % 10
            0.06     0.06       % 11
            0.09     0.11       % 12
            0.20      0         % 13
            0.18      0         % 14
             0       0.14       % 15
             0       0.14       % 16
             0       0.14       % 17
             0        0         % 18
             0        0         % 19
             0        0         % 20
             0        0         % 21
             0        0         % 22
             0        0         % 23
             0        0    ];   % 24        
         
% Perfil de appliances oficinas

app_pro=[    0        0         % 1
             0        0         % 2
             0        0         % 3
             0        0         % 4
             0        0         % 5
             0        0         % 6
             0        0         % 7
            0.25     0.23       % 8
            0.13     0.09       % 9
            0.09     0.05       % 10
            0.09     0.06       % 11
            0.25     0.20       % 12
            0.11      0         % 13
            0.08      0         % 14
             0       0.20       % 15
             0       0.07       % 16
             0       0.10       % 17
             0        0         % 18
             0        0         % 19
             0        0         % 20
             0        0         % 21
             0        0         % 22
             0        0         % 23
             0        0    ];   % 24   
         
% Perfil de ascensores

lift_pro=[   0        0         % 1
             0        0         % 2
             0        0         % 3
             0        0         % 4
             0        0         % 5
             0        0         % 6
             0        0         % 7
            0.25     0.18       % 8
            0.05     0.06       % 9
            0.06     0.06       % 10
            0.16     0.10       % 11
            0.10     0.18       % 12
            0.13      0         % 13
            0.25      0         % 14
             0       0.18       % 15
             0       0.06       % 16
             0       0.18       % 17
             0        0         % 18
             0        0         % 19
             0        0         % 20
             0        0         % 21
             0        0         % 22
             0        0         % 23
             0        0    ];   % 24   
         
%% BATTERY DATA
Pc_max=dataIN.battery(1)/1000;        %Maximum power charge
Pd_max=dataIN.battery(2)/1000;        %Maximum power discharge
E_max=dataIN.battery(3)/1000;         %Maximum battery energy
E_min=dataIN.battery(4)/1000;         %Minimum battery energy
MTTF_bat=dataIN.battery(5);
MTTR_bat=dataIN.battery(6);
batt_ic=dataIN.battery(7);       %Battery Installation Cost
E_ini=E_max;      

%% SIMULATION START
tolerancia=0;

max_years=dataIN.convergence(1);
min_tol=dataIN.convergence(2);

while( (dataIN.years<max_years && (tolerancia>min_tol || tolerancia==0)) || dataIN.years<10 )  %simulation stops wheter dataIN.years is greater than max_years or accepted tolerance is achieved. At least 10 dataIN.years of simulation is performed if tolerance is rapidly achieved
dataIN.years = dataIN.years + 1;
disp('AÑOS');
disp(dataIN.years);
wind_ic = 0;
wind_oc = 0;   
pv_ic = 0;
pv_oc = 0;   
fuel_ic = 0;
fuel_oc = 0;    
gas_ic = 0;
gas_oc = 0;
other_ic = 0;
other_oc = 0;
wind_count=0;
pv_count=0; 
fuel_count=0; 
gas_count=0;
other_count=0; 

%% DEMAND MODEL
    
    aux=0;
    
    if (oc_pro==1)
        aux=1;
    end
    if (oc_pro==2)
        aux=2;
    end
    
    % No consideramos consumo en festivos y findes
    occupation=ones(1,365);
    for k=1:365
        if ((mod(k-6,7)==0)||(mod(k-7,7)==0))
            occupation(k)=0;
        end
        for h=1:length(dataIN.holiday)
            if (k==(dataIN.holiday(h)))
                occupation(k)=0;
            end
        end
    end
        
for d=1:dataIN.roomCount 
    
    for k=1:365                  % Calculamos el consumo de todas las salas
        
if (r_type(d)==1)      % Sala tipo 'oficina'
    
% HORAS DE USO

% horas de uso de luminarias (500 lux)
teta(k) = 0.2163108 + 2 * atan (0.9671396 * tan (0.00860 * (k-186)));
phi(k) = asin (0.39795 * cos (teta(k)));
p = 0.8333 ;

D(k) = 24 - 24/pi * acos(( sin (p*pi/180) + sin (lat*pi/180)...
        * sin (phi(k))) / (cos(lat*pi/180)*cos(phi(k)))) ;                  % daylength in hours

y2 = 7;                                                                     % defining maximum number of artificial lights per day
x2 = 9;                                                                     % assuming that for max. number of artificial light (y2) there is x2 hours of sunlight
y1 = 4;                                                                     % defining minimum number of artificial lights per day
x1 = 15;                                                                    % assuming that for min. number of artificial light (y1) there is x1 hours of sunlight

a_l_h(k) = ((y1-y2)/(x1-x2)) * D(k) + y1 - x1 * ((y1-y2)/(x1-x2));          % artifi. light hours (considering 8 and 4 hours for maximun and minimum hours respectively
a_l_h(k) =  round(a_l_h(k));                                                % artifi. light hours for a single day

light_pro_help = light_pro;
light_working=zeros(a_l_h(k),1);

for i=1:a_l_h(k)
    light_working(i) = randsample(1:1:24,1,true,light_pro_help(:,aux));
                
    light_pro_help(light_working(i),aux)=0;
end

% horas de uso de PC + equipo informático
if (aux==1)
    pc_working=[8 9 10 11 12 13 14];
else
    pc_working=[8 9 10 11 12 15 16 17];
end

% horas de uso de appliances oficinas
app_pro_help=app_pro;
app_working=zeros(hours(3,aux),1);

for i=1:hours(3,aux)
    app_working(i)=randsample(1:1:24,1,true,app_pro_help(:,aux));
    
    app_pro_help(app_working(i),aux)=0;
end

% AJUSTE VECTOR 24 HORAS

% ajuste vector 24 horas para luminarias (500 lux)
light_h=zeros(1,24);

for i=1:length(light_working)
    
    light_h(light_working(i))=1;
    
end

% ajuste vector 24 horas para PC + equipo informático
pc_h=zeros(1,24);

for i=1:length(pc_working)
    
    pc_h(pc_working(i))=1;
    
end

% ajuste vector 24 horas para appliances oficinas
app_h=zeros(1,24);

for i=1:length(app_working)
    
    app_h(app_working(i))=1;
    
end

% CONSUMO ENERGÉTICO

% consumo energético de luminarias (500 lux)
unit_e_daily_light=(((500/luminary(l_type(d)))*4*in_param(d))/1000)*occupation(k);
profile_e_daily_light = unit_e_daily_light*light_h;

% consumo energético de PC + equipo informático
unit_e_daily_pc=consumption(2)*in_param(d)*occupation(k);
profile_e_daily_pc = unit_e_daily_pc*pc_h;

%consumo energético de appliances oficinas
unit_e_daily_app=consumption(3)*occupation(k);
profile_e_daily_app = unit_e_daily_app*app_h;

% Total
total_profile_e_daily{k} = profile_e_daily_light + profile_e_daily_pc + profile_e_daily_app;

else       % Sala tipo 'reunión'
    
% HORAS DE USO
    
% horas de uso de luminarias (300 lux)
teta(k) = 0.2163108 + 2 * atan (0.9671396 * tan (0.00860 * (k-186)));
phi(k) = asin (0.39795 * cos (teta(k)));
p = 0.8333 ;

D(k) = 24 - 24/pi * acos(( sin (p*pi/180) + sin (lat*pi/180)...
        * sin (phi(k))) / (cos(lat*pi/180)*cos(phi(k)))) ;                  % daylength in hours

y2 = 7;                                                                     % defining maximum number of artificial lights per day
x2 = 9;                                                                     % assuming that for max. number of artificial light (y2) there is x2 hours of sunlight
y1 = 4;                                                                     % defining minimum number of artificial lights per day
x1 = 15;                                                                    % assuming that for min. number of artificial light (y1) there is x1 hours of sunlight

a_l_h(k) = ((y1-y2)/(x1-x2)) * D(k) + y1 - x1 * ((y1-y2)/(x1-x2));          % artifi. light hours (considering 7 and 4 hours for maximun and minimum hours respectively
a_l_h(k) =  round(a_l_h(k));                                                % artifi. light hours for a single day

light_pro_help = light_pro;
light_working=zeros(a_l_h(k),1);

for i=1:a_l_h(k)
    light_working(i) = randsample(1:1:24,1,true,light_pro_help(:,aux));
                
    light_pro_help(light_working(i),aux)=0;
end
        
% horas de uso de tomas de uso general
plug_pro_help=plug_pro;
plug_working=zeros(hours(1,aux),1);

for i=1:hours(1,aux)
    plug_working(i)=randsample(1:1:24,1,true,plug_pro_help(:,aux));
    
    plug_pro_help(plug_working(i),aux)=0;
end

% AJUSTE VECTOR 24 HORAS

% ajuste vector 24 horas para luminarias
light_h=zeros(1,24);

for i=1:length(light_working)
    
    light_h(light_working(i))=1;
    
end

% ajuste vector 24 horas para tomas de uso general
plug_h=zeros(1,24);

for i=1:length(plug_working)
    
    plug_h(plug_working(i))=1;
    
end

% CONSUMO ENERGÉTICO

% consumo energético de luminarias (300 lux)
unit_e_daily_light=(((300/luminary(l_type(d)))*in_param(d))/1000)*occupation(k);
profile_e_daily_light = unit_e_daily_light*light_h;

% consumo energético de tomas de uso general
unit_e_daily_plug=consumption(1)*rand*occupation(k);
profile_e_daily_plug = unit_e_daily_plug*plug_h;

% Total
total_profile_e_daily{k} = profile_e_daily_light + profile_e_daily_plug;

end

if (k==1)
     yearly_profile{d} = total_profile_e_daily{1};   
 else
     yearly_profile{d} = horzcat(yearly_profile{d},total_profile_e_daily{k}); 
end

    end
    
end

for k=1:365                % Calculamos el consumo de los servicios comunes
        
% HORAS DE USO
    
% horas de uso de ascensores
lift_pro_help=lift_pro;
lift_working=zeros(hours(4,aux),1);

for i=1:hours(4,aux)
    lift_working(i)=randsample(1:1:24,1,true,lift_pro_help(:,aux));
    
    lift_pro_help(lift_working(i),aux)=0;
end

% horas de uso de aire acondicionado
if (k>=151 && k<=241)
    
if (aux==1)
    AC_working=[8 9 10 11 12 13 14];
else
    AC_working=[8 9 10 11 12 15 16 17];
end

end

% AJUSTE DE HORAS DE USO

% ajuste vector 24 horas para ascensores
lift_h=zeros(1,24);

for i=1:length(lift_working)
    
    lift_h(lift_working(i))=1;
    
end

% ajuste vector 24 horas para aire acondicionado
AC_h=zeros(1,24);

if ((k-365*(fix(k/365))>=151) && (k-365*(fix(k/365))<=241))
    
    for i=1:length(AC_working)
        
        AC_h(AC_working(i))=1;
        
    end
    
end

% CONSUMO ENERGÉTICO

% consumo energético de ascensores
unit_e_daily_lift=consumption(4)*occupation(k);
profile_e_daily_lift = unit_e_daily_lift*lift_h;

% consumo energético de aire acondicionado      
unit_e_daily_AC=(0.0303*surf+0.1031)*occupation(k);
profile_e_daily_AC = unit_e_daily_AC*AC_h;

% Total
common_profile_e_daily{k} = profile_e_daily_lift + profile_e_daily_AC;

if (k==1)
    common_yearly_profile = common_profile_e_daily{1};
else
    common_yearly_profile = horzcat(common_yearly_profile,common_profile_e_daily{k});
end

end

% Introducimos el common_yearly_profile en el yearly_profile
num=dataIN.roomCount+1;

yearly_profile{num} = common_yearly_profile;
        
for a=1:length(yearly_profile)
    
    if (a==1)
        building_profile(dataIN.years,:) = yearly_profile{a};
    else
        building_profile(dataIN.years,:) = building_profile(dataIN.years,:) + yearly_profile{a};
    end
    
end

demandData.building_profile=building_profile;
dataOUT.building_profile=demandData.building_profile;


%% ENERGY GENERATION

if en_wtg == 0
    Pwtg_total = zeros(dataIN.years,8760);
end

if en_pv == 0  
    Ppvmodule_total = zeros(dataIN.years,8760);
end

if en_fuel == 0
    Pfuelcell_total = zeros(dataIN.years,8760);
end

if en_gas == 0
    Pgasturbine_total = zeros(dataIN.years,8760);
end

if en_others == 0
    Pothergen_total = zeros(dataIN.years,8760);
end
    
for i=1:genCount
    
    if dataIN.genConfig(i,1)==1
        
        switch dataIN.genConfig(i,2)
            case 1
                %% WIND GENERATION
                wind_gen_parameters = dataIN.genConfig(i,:);
                n_w = wind_gen_parameters(3);                  % number of WTGs
                Prated_w = wind_gen_parameters(8)/1000;        % Wind Turbine rated power
                MTTF_w = wind_gen_parameters(4);               % Mean Time To Failure per year for WTG  
                MTTR_w = wind_gen_parameters(5);               % Mean Time To Repair per year for WTG
                c = wind_gen_parameters(10);                   % Scale factor c
                kw = wind_gen_parameters(11);                  % Shape factor k
                Vcut_in = wind_gen_parameters(12);             % Cut-in speed
                Vcut_out = wind_gen_parameters(13);            % Cut-out speed
                Vrated_w = wind_gen_parameters(9);             % WT Rated speed

                wind_ic = wind_ic+wind_gen_parameters(6);      % WT installation costs
                wind_oc = wind_gen_parameters(7);              % WT operation costs
                
                if en_wtg == 0
                states_wind_avg=zeros(n_w,8760);
                end
                en_wtg = 1;
                                               
                a = Prated_w * Vcut_in^kw / (Vcut_in^kw - Vrated_w^kw);    %a coefficient for power calculation
                b = Prated_w / (Vrated_w^kw - Vcut_in^kw);                %b coefficient for power calculation

                % Random number generation for wind speeds estimation
                u_w = rand([1,8760]);                                                  % Matrix with 8760 uniformly-distributed random values between 0 and 1 to be used for wind speed calculation
                
                % need to reset these variables for each year of simulation
                Pw = zeros(1,8760);
                v = zeros(1,8760);
                
                    for i=1:8760;

                        v(i) = c * ( -log(u_w(i)) )^(1/kw) ;                                 % Estimated wind speed for every hour in a year
                                                                                            % Calculation of wind turbine power according to different speeds
                        if ( v(i) < Vcut_in )
                            Pw(i) = 0;
                        elseif ( v(i) >= Vcut_in  &&  v(i) < Vrated_w );      
                    %         P(i) = a + b * v(i)^k;
                            Pw(i) = Prated_w * ( v(i)-Vcut_in ) / ( Vrated_w-Vcut_in );
                        elseif  ( v(i) >= Vrated_w && v(i) < Vcut_out );
                            Pw(i) = Prated_w;
                        else 
                            Pw(i) = 0; 
                        end

                    end

                % /////// Operational time calculation using MonteCarlo method ///////

                time_w = 0;
                TTF_w = 0;
                TTR_w = 0;
                state_w = zeros(n_w,8760);
                Pwind_reset = zeros(1,8760);
                wind_count = wind_count+1;                
                
                for i = 1:n_w                   
                                       
                    while (time_w < 8760 )

                        TTF_w = round( -MTTF_w * log(rand(1)) );

                        if(time_w+TTF_w > 8760)

                            for(j= time_w+1 : 8760)
                                state_w(i,j) = 1;
                            end

                        else

                            for(j= time_w+1 : time_w+TTF_w)
                                state_w(i,j) = 1;
                            end

                        end

                        time_w = time_w + TTF_w;

                        if ( time_w < 8760 )

                            TTR_w = round( -MTTR_w * log(rand(1)) );

                            if(time_w+TTR_w > 8760)

                                for(j= time_w+1 : 8760)
                                    state_w(i,j) = 0;
                                end

                            else

                                for(j= time_w+1 : time_w+TTR_w)
                                    state_w(i,j) = 0;
                                end

                                time_w = time_w + TTR_w;

                            end
                        end
                    end
                    
                        states_w_group{wind_count}{i}(dataIN.years,:) = state_w(i,:);

                    for j = 1:8760
                        
                        Pwind_individual{wind_count}{i}(dataIN.years,j)= Pw(j) * state_w(i,j);

                    end
                      
                    Pwind_reset = Pwind_reset + Pwind_individual{wind_count}{i}(dataIN.years,:);
                    Pwind_group{wind_count}(dataIN.years,:) = Pwind_reset;
                    
                    n_w_vec(wind_count)=n_w;
                    
                    time_w = 0;                   
                   
                end                           
                                
            case 2
                %% PV GENERATION
                en_pv = 1;
                pv_gen_parameters=dataIN.genConfig(i,:);
                
                n_pv = pv_gen_parameters(3);                   % Number of PV panels
                Voc = pv_gen_parameters(9);                    % Open circuit voltage
                Isc = pv_gen_parameters(10);                   % Short circuit current
                Vmpp = pv_gen_parameters(11);                  % Voltage at MPP
                Impp = pv_gen_parameters(12);                  % Current at MPP
                Ki = pv_gen_parameters(13);                    % Isc Temperature Factor
                Kv = pv_gen_parameters(14);                    % Voc Temperature Factor
                Not = pv_gen_parameters(8);                    % Normal operating Temperature
                MTTF_pv = pv_gen_parameters(4);                % Mean time to failure per year for pv module                       
                MTTR_pv = pv_gen_parameters(5);                % Mean time to repair per year for pv module
                
                pv_ic = pv_ic+pv_gen_parameters(6);            % PV installation costs
                pv_oc = pv_gen_parameters(7);                  % PV operation costs
                
                Pmpp = Impp * Vmpp;
                FF = (Pmpp) / (Voc * Isc);
                
                k = 0;
                delay = 0;

                h = 12:1:8771;
                delta = zeros(1,365);
                ws = zeros(1,365);
                w = zeros(1,8760);
                cos_zenith = zeros(1,365);
                Sn = zeros(1,8760);
                Sb = zeros(1,8760);
                Sd = zeros(1,8760);
                S = zeros(1,8760);

                % Calculation of the weather profile for each day with Markov Chain implementation
                chain = zeros(1,chain_length);
                starting_value = 1;                                                         % starts at sunny day
                chain(1)=starting_value;                                                    % starts at sunny day

                % chain calculation
                for i=2:chain_length
                        this_step_distribution = Pd(chain(i-1),:);
                        cumulative_distribution = cumsum(this_step_distribution);
                        r = rand();
                        chain(i) = find(cumulative_distribution>r,1);
                end

                for i=1:365

                    delta(i) = sin(((360/365) * ((day(i) + 284))) * pi / 180) * 23.45;        % solar declination angle in degrees
                    ws(i) = acos(-tan(lat*pi/180) * tan(delta(i) * pi / 180));              % sunset hour angle in rad

                    for j=(1+delay):8760

                        w(j) = 2*pi*h(j)/24;                                                % hour angle
                        cos_zenith(j) = sin(lat*pi/180) * sin(delta(i)*pi/180)...           % cosine of zenith angle
                                    + cos(lat*pi/180) * cos(delta(i)*pi/180)*cos(w(j));

                        k = k + 1;

                        % Hourly radiation per month     
                        %January
                        if k <= 744
                            expo(i) = exp(-correl_const(1,4)/cos_zenith(j));                % Calculation of the exponential term exp(-D/cos_zenith)    
                            Sn(j) = correl_const(1,3) * expo(i);
                            Sb(j) = correl_const(1,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(1,2);
                            Sd(j) = correl_const(1,5) * Sn(j) + correl_const(1,6);
                        end
                        %February
                        if k > 744 && k <= 1416
                            expo(i) = exp(-correl_const(2,4)/cos_zenith(j));           
                            Sn(j) = correl_const(2,3) * expo (i);
                            Sb(j) = correl_const(2,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(2,2);
                            Sd(j) = correl_const(2,5) * Sn(j) + correl_const(2,6);
                        end
                        %March
                        if k > 1416 && k <= 2160
                            expo(i) = exp(-correl_const(3,4)/cos_zenith(j));           
                            Sn(j) = correl_const(3,3) * expo (i);
                            Sb(j) = correl_const(3,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(3,2);
                            Sd(j) = correl_const(3,5) * Sn(j) + correl_const(3,6);
                        end
                        %April
                        if k > 2160 && k <= 2880
                            expo(i) = exp(-correl_const(4,4)/cos_zenith(j));           
                            Sn(j) = correl_const(4,3) * expo (i);
                            Sb(j) = correl_const(4,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(4,2);
                            Sd(j) = correl_const(4,5) * Sn(j) + correl_const(4,6);
                        end
                        %May
                        if k > 2880 && k <= 3624
                            expo(i) = exp(-correl_const(5,4)/cos_zenith(j));           
                            Sn(j) = correl_const(5,3) * expo (i);
                            Sb(j) = correl_const(5,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(5,2);
                            Sd(j) = correl_const(5,5) * Sn(j) + correl_const(5,6);
                        end
                        %June
                        if k > 3624 && k <= 4344
                            expo(i) = exp(-correl_const(6,4)/cos_zenith(j));           
                            Sn(j) = correl_const(6,3) * expo (i);
                            Sb(j) = correl_const(6,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(6,2);
                            Sd(j) = correl_const(6,5) * Sn(j) + correl_const(6,6);
                        end
                        %July
                        if k > 4344 && k <= 5088
                            expo(i) = exp(-correl_const(7,4)/cos_zenith(j));           
                            Sn(j) = correl_const(7,3) * expo (i);
                            Sb(j) = correl_const(7,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(7,2);
                            Sd(j) = correl_const(7,5) * Sn(j) + correl_const(7,6);
                        end
                        %August
                        if k > 5088 && k <= 5832
                            expo(i) = exp(-correl_const(8,4)/cos_zenith(j));           
                            Sn(j) = correl_const(8,3) * expo (i);
                            Sb(j) = correl_const(8,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(8,2);
                            Sd(j) = correl_const(8,5) * Sn(j) + correl_const(8,6);
                        end
                        %September
                        if k > 5832 && k <= 6552
                            expo(i) = exp(-correl_const(9,4)/cos_zenith(j));           
                            Sn(j) = correl_const(9,3) * expo (i);
                            Sb(j) = correl_const(9,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(9,2);
                            Sd(j) = correl_const(9,5) * Sn(j) + correl_const(9,6);
                        end
                        %October
                        if k > 6552 && k <= 7296
                            expo(i) = exp(-correl_const(10,4)/cos_zenith(j));           
                            Sn(j) = correl_const(10,3) * expo (i);
                            Sb(j) = correl_const(10,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(10,2);
                            Sd(j) = correl_const(10,5) * Sn(j) + correl_const(10,6);
                        end
                        %November
                        if k > 7296 && k <= 8016
                            expo(i) = exp(-correl_const(11,4)/cos_zenith(j));           
                            Sn(j) = correl_const(11,3) * expo (i);
                            Sb(j) = correl_const(11,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(11,2);
                            Sd(j) = correl_const(11,5) * Sn(j) + correl_const(11,6);
                        end
                        %December
                        if k > 8016 && k <= 8760
                            expo(i) = exp(-correl_const(12,4)/cos_zenith(j));           
                            Sn(j) = correl_const(12,3) * expo (i);
                            Sb(j) = correl_const(12,1) * Sn(j) * cos_zenith(j)...
                                    + correl_const(12,2);
                            Sd(j) = correl_const(12,5) * Sn(j) + correl_const(12,6);
                        end

                        % radiation calculation if ws is the sunset hour angle (>0)
                        if ws(i) >= 0                                                       
                            if cos(w(j)) >= cos(ws(i))
                                S(j) = Sb(j) + Sd(j);
                            else 
                                S(j) = 0;
                            end
                        end
                        % radiation calculation if ws is the sunrise hour angle (<0)
                        if ws(i) < 0                                                        
                            if cos(w(j)) <= cos(ws(i))
                                S(j) = Sb(j) + Sd(j);
                            else 
                                S(j) = 0;
                            end
                        end

                        % in light rainning day the radiation is reduced to half
                        if chain(i) == 2
                            S(j) = S(j)*0.5;
                        end
                        % in heavy rainning day the radiation is reduced to 10%
                        if chain(i) == 3
                            S(j) = S(j)*0.1;
                        end

                    % PV output power calculation

                        Tc(j) = Ta(k) + (S(j)/1000) * (Not - 20)/0.8;
                        Ipv(j) = (S(j)/1000) * (Isc + Ki * (Tc(j) - 25));
                        V(j) = Voc - Kv * Tc(j);
                        Ppv(j) = FF * V(j) * Ipv(j);

                        if Ppv(j) >= Vmpp*Impp
                            Ppv(j) = Vmpp*Impp;
                        end

                        if k >= 8760
                        k = 0;
                        end

                    end   

                    delay = delay + 24;
                end
                Ppv = Ppv/1000; % PV power in kW
                
                % /////// Operational time calculation using MonteCarlo method ///////

                time_pv = 0;
                TTF_pv = 0;
                TTR_pv = 0;
                state_pv = zeros(n_pv,8760);
                Ppv_reset = zeros(1,8760);
                pv_count = pv_count+1;
                
                for i = 1:n_pv
                    
                    while (time_pv < 8760 )

                        TTF_pv = round( -MTTF_pv * log(rand(1)) );

                        if(time_pv+TTF_pv > 8760)

                            for(j= time_pv+1 : 8760)
                                state_pv(i,j) = 1;
                            end

                        else

                            for(j= time_pv+1 : time_pv+TTF_pv)
                                state_pv(i,j) = 1;
                            end

                        end

                        time_pv = time_pv + TTF_pv;

                        if ( time_pv < 8760 )

                            TTR_pv = round( -MTTR_pv * log(rand(1)) );

                            if(time_pv+TTR_pv > 8760)

                                for(j= time_pv+1 : 8760)
                                    state_pv(i,j) = 0;
                                end

                            else

                                for(j= time_pv+1 : time_pv+TTR_pv)
                                    state_pv(i,j) = 0;
                                end

                                time_pv = time_pv + TTR_pv;

                            end
                        end
                    end
                    
                    states_pv_group{pv_count}{i}(dataIN.years,:) = state_pv(i,:);

                    for j = 1:8760
                        
                        Ppv_individual{pv_count}{i}(dataIN.years,j)= Ppv(j) * state_pv(i,j);

                    end
                      
                    Ppv_reset = Ppv_reset + Ppv_individual{pv_count}{i}(dataIN.years,:);
                    Ppv_group{pv_count}(dataIN.years,:) = Ppv_reset;
                    
                    n_pv_vec(pv_count)=n_pv;
                    time_pv = 0;

                end                                                                                                                
                                
            case 3
                %% FUEL CELL GENERATION
                en_fuel = 1;
                fuel_count = fuel_count+1;
                
                fuel_gen_parameters=dataIN.genConfig(i,:);
                n_fuel(fuel_count)=fuel_gen_parameters(3);                 % Number of cells
                Pfuel(fuel_count)=fuel_gen_parameters(8)/1000;             % Rated Power of the single cell
                Pfuel_min(fuel_count) = fuel_gen_parameters(9)/1000;       % minimum Power of the single cell
                MTTF_fuel=fuel_gen_parameters(4);                          % Cell MTTF 
                MTTR_fuel =fuel_gen_parameters(5);                         % Cell MTTR
                
                fuel_ic = fuel_ic+fuel_gen_parameters(6);                  % Fuel Cell installation costs
                fuel_oc = fuel_gen_parameters(7);                          % Fuel Cell operation costs
                
                time_fuel = 0;
                TTF_fuel = 0;
                TTR_fuel = 0;
                state_fuel = zeros(n_fuel(fuel_count),8760);
%                 Pfuel_reset = zeros(1,8760);
                
                for i = 1:n_fuel(fuel_count)
                                    
                    while (time_fuel < 8760 )

                        TTF_fuel = round( -MTTF_fuel * log(rand(1)) );

                        if(time_fuel+TTF_fuel > 8760)

                            for(j= time_fuel+1 : 8760)
                                state_fuel(i,j) = 1;
                            end

                        else

                            for(j= time_fuel+1 : time_fuel+TTF_fuel)
                                state_fuel(i,j) = 1;
                            end

                        end

                        time_fuel = time_fuel + TTF_fuel;

                        if ( time_fuel < 8760 )

                            TTR_fuel = round( -MTTR_fuel * log(rand(1)) );

                            if(time_fuel+TTR_fuel > 8760)

                                for(j= time_fuel+1 : 8760)
                                    state_fuel(i,j) = 0;
                                end

                            else

                                for(j= time_fuel+1 : time_fuel+TTR_fuel)
                                    state_fuel(i,j) = 0;
                                end

                                time_fuel = time_fuel + TTR_fuel;

                            end
                        end
                    end
                   
                    states_fuel_group{fuel_count}{i}(dataIN.years,:) = state_fuel(i,:);

                    for j = 1:8760
                        
                        Pfuel_individual{fuel_count}{i}(dataIN.years,j)= Pfuel(fuel_count) * state_fuel(i,j);

                    end
                    
                    time_fuel = 0;

                end                              

            case 4
                %% GAS TURBINE GENERATOR
                en_gas = 1;
                gas_count = gas_count + 1;
                gas_gen_parameters=dataIN.genConfig(i,:);              
                n_gas(gas_count)=gas_gen_parameters(3);                % Number of micro gas turbines
                Pgas(gas_count)=gas_gen_parameters(8)/1000;            % Rated Power of the MGT
                Pgas_min(gas_count)=gas_gen_parameters(9)/1000;        % minimum Power of the MGT
                MTTF_gas=gas_gen_parameters(4);                        % Gas MTTF 
                MTTR_gas =gas_gen_parameters(5);                       % Gas MTTR
                gas_ic = gas_ic+gas_gen_parameters(6);                 % Gas installation costs
                gas_oc = gas_gen_parameters(7);                        % Gas operation costs
                
                time_gas = 0;
                TTF_gas = 0;
                TTR_gas = 0;              
                state_gas = zeros(n_gas(gas_count),8760);
                                
                for i = 1:n_gas(gas_count)
                    
                    while (time_gas < 8760 )

                        TTF_gas = round( -MTTF_gas * log(rand(1)) );

                        if(time_gas+TTF_gas > 8760)

                            for(j= time_gas+1 : 8760)
                                state_gas(i,j) = 1;
                            end

                        else

                            for(j= time_gas+1 : time_gas+TTF_gas)
                                state_gas(i,j) = 1;
                            end

                        end

                        time_gas = time_gas + TTF_gas;

                        if ( time_gas < 8760 )

                            TTR_gas = round( -MTTR_gas * log(rand(1)) );

                            if(time_gas+TTR_gas > 8760)

                                for(j= time_gas+1 : 8760)
                                    state_gas(i,j) = 0;
                                end

                            else

                                for(j= time_gas+1 : time_gas+TTR_gas)
                                    state_gas(i,j) = 0;
                                end

                                time_gas = time_gas + TTR_gas;

                            end
                        end
                    end
                    
                    states_gas_group{gas_count}{i}(dataIN.years,:) = state_gas(i,:);

                    for j = 1:8760
                        
                        Pgas_individual{gas_count}{i}(dataIN.years,j)= Pgas(gas_count) * state_gas(i,j);

                    end                      
                    
                    time_gas = 0;

                end                               
                                             
            case 5
                %% OTHER GENERATION  
                en_others = 1;
                other_count = other_count + 1;
                other_gen_parameters=dataIN.genConfig(i,:);                              
                n_other(other_count)=other_gen_parameters(3);                 % Number of Other Gen
                Pother(other_count)=other_gen_parameters(8)/1000;             % Rated Power of Other Gen
                Pother_min(other_count)=other_gen_parameters(9)/1000;         % minimum Power of Other Gen
                MTTF_other=other_gen_parameters(4);                           % Other Gen MTTF 
                MTTR_other =other_gen_parameters(5);                          % Other Gen MTTR
                other_ic = other_ic+other_gen_parameters(6);                  % Other Gen installation costs
                other_oc = other_gen_parameters(7);                           % Other Gen operation costs
                
                time_other = 0;
                TTF_other = 0;
                TTR_other = 0;              
                state_other = zeros(n_other(other_count),8760);             
                
                for i = 1:n_other(other_count)
                    
                    while (time_other < 8760 )

                        TTF_other = round( -MTTF_other * log(rand(1)) );

                        if(time_other+TTF_other > 8760)

                            for(j= time_other+1 : 8760)
                                state_other(i,j) = 1;
                            end

                        else

                            for(j= time_other+1 : time_other+TTF_other)
                                state_other(i,j) = 1;
                            end

                        end

                        time_other = time_other + TTF_other;

                        if ( time_other < 8760 )

                            TTR_other = round( -MTTR_other * log(rand(1)) );

                            if(time_other+TTR_other > 8760)

                                for(j= time_other+1 : 8760)
                                    state_other(i,j) = 0;
                                end

                            else

                                for(j= time_other+1 : time_other+TTR_other)
                                    state_other(i,j) = 0;
                                end

                                time_other = time_other + TTR_other;

                            end
                        end
                    end

                    states_other_group{other_count}{i}(dataIN.years,:) = state_other(i,:);

                    for j = 1:8760
                        
                        Pother_individual{other_count}{i}(dataIN.years,j)= Pother(other_count) * state_other(i,j);

                    end                    
                    
                    time_other = 0;

                end                            
                
        end
                
    else
        genData.generator{i}=0;
        dataOUT.generator{i}=0;       %saving data
               
    end   
    
end

%% Crear estructuras con generacion media horaria por año para cada grupo de generadores

for i=1:wind_count
    
    for j = 1:n_w_vec(i)
        Pwind_individual_avg_reset=zeros(1,8760);
        
        for y=1:dataIN.years
            Pwind_individual_avg_reset = Pwind_individual_avg_reset + Pwind_individual{i}{j}(y,:); 
        end
        Pwind_individual_avg{i}(j,:)=Pwind_individual_avg_reset/dataIN.years; %Generacion media anual de cada aerogenerador
    end
    
    Pwind_group_avg_reset=zeros(1,8760);
    for y=1:dataIN.years
        Pwind_group_avg_reset = Pwind_group_avg_reset + Pwind_group{i}(y,:);
    end
    dataOUT.Pwind_group_avg{i}=Pwind_group_avg_reset/dataIN.years; %Generacion media anual de cada grupo de aerogeneradores
    
end

for i=1:pv_count
    
    for j = 1:n_pv_vec(i)
        Ppv_individual_avg_reset=zeros(1,8760);
        
        for y=1:dataIN.years
            Ppv_individual_avg_reset = Ppv_individual_avg_reset + Ppv_individual{i}{j}(y,:);
        end
        Ppv_individual_avg{i}(j,:)=Ppv_individual_avg_reset/dataIN.years; %Generacion media anual de cada panel
    end
    
    Ppv_group_avg_reset=zeros(1,8760);
    for y=1:dataIN.years
        Ppv_group_avg_reset = Ppv_group_avg_reset + Ppv_group{i}(y,:);
    end
    dataOUT.Ppv_group_avg{i}=Ppv_group_avg_reset/dataIN.years; %Generacion media anual de cada grupo de paneles
    
end

%% TOTAL RENEWABLE GENERATION

Prenewables_reset = zeros(1,8760);

for i = 1:wind_count
    Prenewables_reset = Prenewables_reset + Pwind_group{i}(dataIN.years,:);
end

for i = 1:pv_count
    Prenewables_reset = Prenewables_reset + Ppv_group{i}(dataIN.years,:);
end
Prenewables(dataIN.years,:)=Prenewables_reset;
Pgen(dataIN.years,:) = Prenewables(dataIN.years,:);

%% BATTERY
if en_bat==0;
Ebattery_whole = zeros(1,8760);
end

                % /////// Operational time calculation using MonteCarlo method ///////
                time_bat = 0;
                TTF_bat = 0;
                TTR_bat = 0;
                                   
                    while (time_bat < 8760 )

                        TTF_bat = round( -MTTF_bat * log(rand(1)) );

                        if(time_bat+TTF_bat > 8760)

                            for(j= time_bat+1 : 8760)
                                state_bat(dataIN.years,j) = 1;
                            end

                        else

                            for(j= time_bat+1 : time_bat+TTF_bat)
                                state_bat(dataIN.years,j) = 1;
                            end

                        end

                        time_bat = time_bat + TTF_bat;

                        if ( time_bat < 8760 )

                            TTR_bat = round( -MTTR_bat * log(rand(1)) );

                            if(time_bat+TTR_bat > 8760)

                                for(j= time_bat+1 : 8760)
                                    state_bat(dataIN.years,j) = 0;
                                end

                            else

                                for(j= time_bat+1 : time_bat+TTR_bat)
                                    state_bat(dataIN.years,j) = 0;
                                end

                                time_bat = time_bat + TTR_bat;

                            end
                        end
                    end

en_bat=1;
E_reset = zeros (1,8760);
E_reset(1) = E_ini;

for i = 1:8760   
    
    if (state_bat(dataIN.years,i)>0)
    
        if Pgen(dataIN.years,i) > building_profile(dataIN.years,i)
            
            for m=1:fuel_count
                for n=1:n_fuel(m)
                    Pfuel_individual{m}{n}(dataIN.years,i)=0;
                end
            end
            for m=1:gas_count
                for n=1:n_gas(m)
                    Pgas_individual{m}{n}(dataIN.years,i)=0;
                end
            end
            for m=1:other_count
                for n=1:n_other(m)
                    Pother_individual{m}{n}(dataIN.years,i)=0;
                end
            end          

            if (i==1)
                Eaux = E_ini;
            else
                Eaux = E_reset(1,i-1);
            end

            if ( Eaux >= E_max )
                Pc = 0;
                Egrid(dataIN.years,i) = Pgen(dataIN.years,i) - building_profile(dataIN.years,i);
            else
                if ( Pgen(dataIN.years,i) - building_profile(dataIN.years,i) > Pc_max )
                    Pc = Pc_max;
                    Egrid(dataIN.years,i) = Pgen(dataIN.years,i) - Pc - building_profile(dataIN.years,i);
                else
                     Pc = Pgen(dataIN.years,i) - building_profile(dataIN.years,i);
                     Egrid(dataIN.years,i) = 0;
                end
            end

            if (i==1)
                Eaux = E_ini;
            else
                Eaux = E_reset(1,i-1);
            end

            E_reset(1,i) = Eaux + Pc;

            if ( E_reset(1,i) > E_max )
                E_reset(1,i) = E_max;
            else
                E_reset(1,i) = E_reset(1,i);             
            end


        else

            if (i==1)
                Eaux = E_ini;
            else
                Eaux = E_reset(1,i-1);
            end

                if ( Eaux <= E_min )
                    Pc = 0;
                    %% si no podemos tirar de bateria y fuel es el mas barato
                    if fuel_oc <= gas_oc && fuel_oc <= other_oc 

                        for m=1:fuel_count
                            for n = 1:n_fuel(m)
                                if states_fuel_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          

                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:gas_count
                                            for s=1:n_gas(r)
                                                Pgas_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                        for r=1:other_count
                                            for s=1:n_other(r)
                                                Pother_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end

                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                    end
                                else
                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                end
                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pfuel_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            % si fuel es el mas barato y other el mas caro
                            if gas_oc <= other_oc
                                for m = 1:gas_count
                                    for n = 1:n_gas(m)
                                        if states_gas_group{m}{n}(dataIN.years,i)>0
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pgas(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;                            
                                                    for r=1:other_count
                                                        for s=1:n_other(r)
                                                            Pother_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                            end
                                        else
                                            Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                        end
                                        Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                                    for m = 1:other_count
                                        for n = 1:n_other(m)
                                            if states_other_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                end
                                            else
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                                        end
                                    end
                                end
                            % si fuel es el mas barato y gas el mas caro    
                            else
                                for m = 1:other_count
                                    for n = 1:n_other(m)
                                        if states_other_group{m}{n}(dataIN.years,i)>0
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;
                                                    for r=1:gas_count
                                                        for s=1:n_gas(r)
                                                            Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                            end
                                        else
                                            Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                        end
                                        Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                                    for m = 1:gas_count
                                        for n = 1:n_gas(m)
                                            if states_gas_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pgas_min(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                end
                                            else
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                                        end
                                    end
                                end
                            end

                        end

                    end

                    %% si no podemos tirar de bateria y gas es el mas barato
                    if gas_oc < fuel_oc && gas_oc <= other_oc
                        for m=1:gas_count
                            for n=1:n_gas(m)
                                if states_gas_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:fuel_count
                                            for s=1:n_fuel(r)
                                                Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                        for r=1:other_count
                                            for s=1:n_other(r)
                                                Pother_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                    end
                                else
                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            % si gas es el mas barato y other el mas caro
                            if fuel_oc <= other_oc
                                for m=1:fuel_count
                                    for n=1:n_fuel(m)
                                        if states_fuel_group{m}{n}(dataIN.years,i)>0
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;
                                                for r=1:other_count
                                                    for s=1:n_other(r)
                                                        Pother_individual{r}{s}(dataIN.years,i)=0;
                                                    end
                                                end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                            end
                                        else
                                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                        end
                                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                                    for m=1:other_count
                                        for n=1:n_other(m)
                                            if states_other_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother_min(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                end
                                            else
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                            end
                                            Pgen(dataIN.years,i)= Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                        end
                                    end
                                end
                            % si gas es el mas barato y fuel el mas caro    
                            else
                                for m=1:other_count
                                    for n=1:n_other(m)
                                        if states_other_group{m}{n}(dataIN.years,i)>0
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;                            
                                                for r=1:fuel_count
                                                    for s=1:n_fuel(r)
                                                        Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                    end
                                                end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                                Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                            end
                                        else
                                            Pother_individual{m}{n}(dataIN.years,i) = 0;
                                        end
                                        Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                                    for m = 1:fuel_count
                                        for n = 1:n_fuel(m)
                                            if states_fuel_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                end
                                            else
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                        end
                                    end
                                end
                            end

                        end

                    end

                    %% si no podemos tirar de bateria y other es el mas barato
                    if other_oc < fuel_oc && other_oc < gas_oc
                        for m = 1:other_count
                            for n = 1:n_other(m)
                                if states_other_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:fuel_count
                                            for s=1:n_fuel(r)
                                                Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                        for r=1:gas_count
                                            for s=1:n_gas(r)
                                                Pgas_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                    end
                                else
                                    Pother_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                            end
                        end
                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            % si other es el mas barato y gas el mas caro
                            if fuel_oc <= gas_oc
                                for m=1:fuel_count
                                    for n=1:n_fuel(m)
                                        if states_fuel_group{m}{n}(dataIN.years,i)>0
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;
                                                for r=1:gas_count
                                                    for s=1:n_gas(r)
                                                        Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                    end
                                                end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                                Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                            end
                                        else
                                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                        end
                                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                                    for m = 1:gas_count
                                        for n = 1:n_gas(m)
                                            if states_gas_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                end
                                            else
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                        end
                                    end
                                end
                            % si other es el mas barato y fuel el mas caro    
                            else
                                for m=1:gas_count
                                    for n=1:n_gas(m)
                                        if states_gas_group{m}{n}(dataIN.years,i)
                                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;                                 
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                Egrid(dataIN.years,i) = 0;
                                                for r=1:fuel_count
                                                    for s=1:n_fuel(r)
                                                        Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                    end
                                                end
                                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                                Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                            end
                                        else
                                            Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                        end
                                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                    end
                                end

                                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                                    for m=1:fuel_count
                                        for n=1:n_fuel(m)
                                            if states_fuel_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                                    Egrid(dataIN.years,i) = 0;
                                                elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                end
                                            else
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                            end
                                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);                               
                                        end
                                    end
                                end
                            end

                        end

                    end                  
                                        
                    if Pgen(dataIN.years,i)<building_profile(dataIN.years,i)
                        Egrid(dataIN.years,i) = - ( building_profile(dataIN.years,i) - Pgen(dataIN.years,i) );
                    end
                    
                else

                    if ( building_profile(dataIN.years,i) - Pgen(dataIN.years,i) > Pd_max )
                        Pc = -Pd_max;
                        
                        %% si tiramos de bateria y fuel es el mas barato
                        if fuel_oc <= gas_oc && fuel_oc <= other_oc 

                            for m=1:fuel_count
                                for n = 1:n_fuel(m)
                                    if states_fuel_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel_min(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                            Egrid(dataIN.years,i) = 0;
                                            for r=1:gas_count
                                                for s=1:n_gas(r)
                                                    Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                            for r=1:other_count
                                                for s=1:n_other(r)
                                                    Pother_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end

                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                        end
                                    else
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                    end
                                    Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pfuel_individual{m}{n}(dataIN.years,i);
                                end
                            end

                            if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                % si fuel es el mas barato y other el mas caro
                                if gas_oc <= other_oc
                                    for m = 1:gas_count
                                        for n = 1:n_gas(m)
                                            if states_gas_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas_min(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;                            
                                                        for r=1:other_count
                                                            for s=1:n_other(r)
                                                                Pother_individual{r}{s}(dataIN.years,i)=0;
                                                            end
                                                        end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                end
                                            else
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if Pgen(dataIN.years,i) + abs(Pc)< building_profile(dataIN.years,i)
                                        for m = 1:other_count
                                            for n = 1:n_other(m)
                                                if states_other_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother_min(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pother(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                    end
                                                else
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;
                                                end
                                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                                            end
                                        end
                                    end
                                % si fuel es el mas barato y gas el mas caro    
                                else
                                    for m = 1:other_count
                                        for n = 1:n_other(m)
                                            if states_other_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother_min(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;
                                                        for r=1:gas_count
                                                            for s=1:n_gas(r)
                                                                Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                            end
                                                        end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                end
                                            else
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if (Pgen(dataIN.years,i) + abs(Pc))< building_profile(dataIN.years,i)
                                        for m = 1:gas_count
                                            for n = 1:n_gas(m)
                                                if states_gas_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pgas_min(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pgas_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i)+ abs(Pc)) < Pgas(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pgas(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                    end
                                                else
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                                end
                                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                                            end
                                        end
                                    end
                                end

                            end

                        end

                        %% si gas es el mas barato
                        if gas_oc < fuel_oc && gas_oc <= other_oc
                            for m=1:gas_count
                                for n=1:n_gas(m)
                                    if states_gas_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas_min(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                            Egrid(dataIN.years,i) = 0;
                                            for r=1:fuel_count
                                                for s=1:n_fuel(r)
                                                    Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                            for r=1:other_count
                                                for s=1:n_other(r)
                                                    Pother_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                        end
                                    else
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                    end
                                    Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                end
                            end

                            if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                % si gas es el mas barato y other el mas caro
                                if fuel_oc <= other_oc
                                    for m=1:fuel_count
                                        for n=1:n_fuel(m)
                                            if states_fuel_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel_min(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pfuel_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;
                                                    for r=1:other_count
                                                        for s=1:n_other(r)
                                                            Pother_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                end
                                            else
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                            end
                                            Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if Pgen(dataIN.years,i) + abs(Pc)< building_profile(dataIN.years,i)
                                        for m=1:other_count
                                            for n=1:n_other(m)
                                                if states_other_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pother_min(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pother(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother(m)
                                                        Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                    end
                                                else
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                                end
                                                Pgen(dataIN.years,i)= Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                            end
                                        end
                                    end
                                % si gas es el mas barato y fuel el mas caro    
                                else
                                    for m=1:other_count
                                        for n=1:n_other(m)
                                            if states_other_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother_min(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))< Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;                            
                                                    for r=1:fuel_count
                                                        for s=1:n_fuel(r)
                                                            Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pother(m)
                                                    Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                                end
                                            else
                                                Pother_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                        for m = 1:fuel_count
                                            for n = 1:n_fuel(m)
                                                if states_fuel_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel_min(m)
                                                                  
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i)+ abs(Pc)) < Pfuel(m)
                                                        Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc))>= Pfuel(m)
                                                        Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                    end
                                                else
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                                                end
                                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                            end
                                        end
                                    end
                                end

                            end

                        end

                        %% si other es el mas barato
                        if other_oc < fuel_oc && other_oc < gas_oc
                            for m = 1:other_count
                                for n = 1:n_other(m)
                                    if states_other_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother_min(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pother_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                            Egrid(dataIN.years,i) = 0;
                                            for r=1:fuel_count
                                                for s=1:n_fuel(r)
                                                    Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                            for r=1:gas_count
                                                for s=1:n_gas(r)
                                                    Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                        elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                        end
                                    else
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;
                                    end
                                    Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                end
                            end
                            if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                % si other es el mas barato y gas el mas caro
                                if fuel_oc <= gas_oc
                                    for m=1:fuel_count
                                        for n=1:n_fuel(m)
                                            if states_fuel_group{m}{n}(dataIN.years,i)>0         
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel_min(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i)+ abs(Pc)) >= Pfuel_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i)+ abs(Pc)) < Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;
                                                    for r=1:gas_count
                                                        for s=1:n_gas(r)
                                                            Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel(m)
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                end
                                            else
                                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                        for m = 1:gas_count
                                            for n = 1:n_gas(m)
                                                if states_gas_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas_min(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas(m)
                                                        Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                    end
                                                else
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                                end
                                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                            end
                                        end
                                    end
                                % si other es el mas barato y fuel el mas caro    
                                else
                                    for m=1:gas_count
                                        for n=1:n_gas(m)
                                            if states_gas_group{m}{n}(dataIN.years,i)>0
                                                if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas_min(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;                                 
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                    Egrid(dataIN.years,i) = 0;
                                                    for r=1:fuel_count
                                                        for s=1:n_fuel(r)
                                                            Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                                        end
                                                    end
                                                elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pgas(m)
                                                    Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                                end
                                            else
                                                Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                            end
                                            Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                        end
                                    end

                                    if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                                        for m=1:fuel_count
                                            for n=1:n_fuel(m)
                                                if states_fuel_group{m}{n}(dataIN.years,i)>0
                                                    if building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel_min(m)
                                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel_min(m) && building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) < Pfuel(m)
                                                        Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc));
                                                        Egrid(dataIN.years,i) = 0;
                                                    elseif building_profile(dataIN.years,i) - (Pgen(dataIN.years,i) + abs(Pc)) >= Pfuel(m)
                                                        Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                                    end
                                                else
                                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                                                end
                                            Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);                               
                                            end
                                        end
                                    end
                                end

                            end

                        end
                        
                        if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
                            Egrid(dataIN.years,i) = -( building_profile(dataIN.years,i) - Pgen(dataIN.years,i) - abs(Pc));
                        else
                            Egrid(dataIN.years,i) = 0;
                        end
                                               
                    else
                        Pc = - ( building_profile(dataIN.years,i) - Pgen(dataIN.years,i) ) ;
                        Egrid(dataIN.years,i) = 0;
                        for m=1:fuel_count
                            for n=1:n_fuel(m)
                                Pfuel_individual{m}{n}(dataIN.years,i)=0;
                            end
                        end
                        for m=1:gas_count
                            for n=1:n_gas(m)
                                Pgas_individual{m}{n}(dataIN.years,i)=0;
                            end
                        end
                        for m=1:other_count
                            for n=1:n_other(m)
                                Pother_individual{m}{n}(dataIN.years,i)=0;
                            end
                        end
                    end
                                        
                end

            if (i==1)
                Eaux = E_ini;
            else
                Eaux = E_reset(1,i-1);
            end

            E_reset(1,i) = Eaux - abs(Pc);

            if ( E_reset(1,i) < E_min )
                E_reset(1,i) = E_min;
            else
                E_reset(1,i) = E_reset(1,i);             
            end

        end
        
    else % Si la bateria no funciona
        
        Pc=0;
        
        if Pgen(dataIN.years,i) > building_profile(dataIN.years,i)
    
        Egrid(dataIN.years,i) = Pgen(dataIN.years,i) - building_profile(dataIN.years,i);
        
        for m=1:fuel_count
            for n=1:n_fuel(m)
                Pfuel_individual{m}{n}(dataIN.years,i)=0;
            end
        end
        for m=1:gas_count
            for n=1:n_gas(m)
                Pgas_individual{m}{n}(dataIN.years,i)=0;
            end
        end
        for m=1:other_count
            for n=1:n_other(m)
                Pother_individual{m}{n}(dataIN.years,i)=0;
            end
        end        
    
        else       
            %% si la bateria no funciona y fuel es el mas barato
            if fuel_oc <= gas_oc && fuel_oc <= other_oc 

                for m=1:fuel_count
                    for n = 1:n_fuel(m)
                        if states_fuel_group{m}{n}(dataIN.years,i)>0         
                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                Egrid(dataIN.years,i) = 0;
                                for r=1:gas_count
                                    for s=1:n_gas(r)
                                        Pgas_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                                for r=1:other_count
                                    for s=1:n_other(r)
                                        Pother_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                            end
                        else
                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                        end
                        Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pfuel_individual{m}{n}(dataIN.years,i);
                    end
                end

                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                    % si fuel es el mas barato y other el mas caro
                    if gas_oc <= other_oc
                        for m = 1:gas_count
                            for n = 1:n_gas(m)
                                if states_gas_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;                            
                                            for r=1:other_count
                                                for s=1:n_other(r)
                                                    Pother_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                    end
                                else
                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                            for m = 1:other_count
                                for n = 1:n_other(m)
                                    if states_other_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                        end
                                    else
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;
                                    end
                                    Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                                end
                            end
                        end
                    % si fuel es el mas barato y gas el mas caro    
                    else
                        for m = 1:other_count
                            for n = 1:n_other(m)
                                if states_other_group{m}{n}(dataIN.years,i)>0                                
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                            for r=1:gas_count
                                                for s=1:n_gas(r)
                                                    Pgas_individual{r}{s}(dataIN.years,i)=0;
                                                end
                                            end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                    end
                                else
                                    Pother_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pother_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                            for m = 1:gas_count
                                for n = 1:n_gas(m)
                                    if states_gas_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pgas_min(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                        end
                                    else
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                    end
                                    Pgen(dataIN.years,i)=Pgen(dataIN.years,i)+Pgas_individual{m}{n}(dataIN.years,i);
                                end
                            end
                        end
                    end

                end

            end
        
            %% si la bateria no funciona y gas es el mas barato
            if gas_oc < fuel_oc && gas_oc <= other_oc
                for m=1:gas_count
                    for n=1:n_gas(m)
                        if states_gas_group{m}{n}(dataIN.years,i)>0
                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                Egrid(dataIN.years,i) = 0;
                                for r=1:fuel_count
                                    for s=1:n_fuel(r)
                                        Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                                for r=1:other_count
                                    for s=1:n_other(r)
                                        Pother_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                            end
                        else
                            Pgas_individual{m}{n}(dataIN.years,i) = 0;
                        end
                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                    end
                end

                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                    % si gas es el mas barato y other el mas caro
                    if fuel_oc <= other_oc
                        for m=1:fuel_count
                            for n=1:n_fuel(m)
                                if states_fuel_group{m}{n}(dataIN.years,i)>0         
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:other_count
                                            for s=1:n_other(r)
                                                Pother_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                    end
                                else
                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i)< building_profile(dataIN.years,i)
                            for m=1:other_count
                                for n=1:n_other(m)
                                    if states_other_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother_min(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                            Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                        end
                                    else
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;          
                                    end
                                    Pgen(dataIN.years,i)= Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                                end
                            end
                        end
                    % si gas es el mas barato y fuel el mas caro    
                    else
                        for m=1:other_count
                            for n=1:n_other(m)
                                if states_other_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = 0;                                 
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i)< Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;                            
                                        for r=1:fuel_count
                                            for s=1:n_fuel(r)
                                                Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pother(m)
                                        Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                                    end
                                else
                                    Pother_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            for m = 1:fuel_count
                                for n = 1:n_fuel(m)
                                    if states_fuel_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i)>= Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                        end
                                    else
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                    end
                                    Pgen(dataIN.years,i)=Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                                end
                            end
                        end
                    end

                end

            end
        
            %% si la bateria no funciona y other es el mas barato
            if other_oc < fuel_oc && other_oc < gas_oc
                for m = 1:other_count
                    for n = 1:n_other(m)
                        if states_other_group{m}{n}(dataIN.years,i)>0
                            if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother_min(m)
                                Pother_individual{m}{n}(dataIN.years,i) = 0;          
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pother_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pother(m)
                                Pother_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                Egrid(dataIN.years,i) = 0;
                                for r=1:fuel_count
                                    for s=1:n_fuel(r)
                                        Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                                for r=1:gas_count
                                    for s=1:n_gas(r)
                                        Pgas_individual{r}{s}(dataIN.years,i)=0;
                                    end
                                end
                            elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pother(m)
                                Pother_individual{m}{n}(dataIN.years,i) = Pother(m);           
                            end
                        else
                            Pother_individual{m}{n}(dataIN.years,i) = 0;
                        end
                        Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pother_individual{m}{n}(dataIN.years,i);
                    end
                end
                if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                    % si other es el mas barato y gas el mas caro
                    if fuel_oc <= gas_oc
                        for m=1:fuel_count
                            for n=1:n_fuel(m)
                                if states_fuel_group{m}{n}(dataIN.years,i)>0       
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:gas_count
                                            for s=1:n_gas(r)
                                                Pgas_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                        Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                    end
                                else
                                    Pfuel_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            for m = 1:gas_count
                                for n = 1:n_gas(m)
                                    if states_gas_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                            Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                        end
                                    else
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                    end
                                    Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                                end
                            end
                        end
                    % si other es el mas barato y fuel el mas caro    
                    else
                        for m=1:gas_count
                            for n=1:n_gas(m)
                                if states_gas_group{m}{n}(dataIN.years,i)>0
                                    if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas_min(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = 0;                                 
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                        Egrid(dataIN.years,i) = 0;
                                        for r=1:fuel_count
                                            for s=1:n_fuel(r)
                                                Pfuel_individual{r}{s}(dataIN.years,i)=0;
                                            end
                                        end
                                    elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pgas(m)
                                        Pgas_individual{m}{n}(dataIN.years,i) = Pgas(m);           
                                    end
                                else
                                    Pgas_individual{m}{n}(dataIN.years,i) = 0;
                                end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pgas_individual{m}{n}(dataIN.years,i);
                            end
                        end

                        if Pgen(dataIN.years,i) < building_profile(dataIN.years,i)
                            for m=1:fuel_count
                                for n=1:n_fuel(m)
                                    if states_fuel_group{m}{n}(dataIN.years,i)>0
                                        if building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel_min(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel_min(m) && building_profile(dataIN.years,i) - Pgen(dataIN.years,i) < Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = building_profile(dataIN.years,i) - Pgen(dataIN.years,i);
                                            Egrid(dataIN.years,i) = 0;
                                        elseif building_profile(dataIN.years,i) - Pgen(dataIN.years,i) >= Pfuel(m)
                                            Pfuel_individual{m}{n}(dataIN.years,i) = Pfuel(m);           
                                        end
                                    else
                                        Pfuel_individual{m}{n}(dataIN.years,i) = 0;          
                                    end
                                Pgen(dataIN.years,i) = Pgen(dataIN.years,i) + Pfuel_individual{m}{n}(dataIN.years,i);                               
                                end
                            end
                        end
                    end
            
                end
            
            end                                  
             
        end          
        
    end
    
    Pgeneration (dataIN.years,i) = Pgen(dataIN.years,i) + abs(Pc);
    
    if Pgen(dataIN.years,i) + abs(Pc) < building_profile(dataIN.years,i)
        Egrid(dataIN.years,i)= -(building_profile(dataIN.years,i)-Pgen(dataIN.years,i)-abs(Pc));
    end
    
end 

E(dataIN.years,:)=E_reset(1,:);

dataOUT.Ebattery=E(dataIN.years,:);           %Battery Energy
dataOUT.Egrid=Egrid(dataIN.years,:);          %Grid Energy

%% Generacion convencional

for i=1:fuel_count
      
    Pfuel_reset = zeros(1,8760);
    
    for j = 1:n_fuel(i)
        Pfuel_individual_avg_reset=zeros(1,8760);       
        Pfuel_individual_avg_reset = Pfuel_individual_avg_reset + Pfuel_individual{i}{j}(dataIN.years,:);
        Pfuel_individual_avg{i}(j,:)=Pfuel_individual_avg_reset/dataIN.years; %Generacion media anual de cada fuel cell
        Pfuel_reset = Pfuel_reset + Pfuel_individual{i}{j}(dataIN.years,:);
        Pfuel_group{i}(dataIN.years,:) = Pfuel_reset;  %Generacion anual de cada grupo de fuel cells   
    end
    
    Pfuel_group_avg_reset=zeros(1,8760);
    for y=1:dataIN.years
        Pfuel_group_avg_reset = Pfuel_group_avg_reset + Pfuel_group{i}(y,:);
    end
    dataOUT.Pfuel_group_avg{i}=Pfuel_group_avg_reset/dataIN.years; %Generacion media anual de cada grupo de fuel cells
    
end


for i=1:gas_count

    Pgas_reset = zeros(1,8760);
    
    for j = 1:n_gas(i)
        Pgas_individual_avg_reset=zeros(1,8760);      
        Pgas_individual_avg_reset = Pgas_individual_avg_reset + Pgas_individual{i}{j}(dataIN.years,:);
        Pgas_individual_avg{i}(j,:)=Pgas_individual_avg_reset/dataIN.years; %Generacion media anual de cada microgas turbine
        Pgas_reset = Pgas_reset + Pgas_individual{i}{j}(dataIN.years,:);
        Pgas_group{i}(dataIN.years,:) = Pgas_reset;    %Generacion anual de cada grupo de microgas turbines
    end
    
    Pgas_group_avg_reset=zeros(1,8760);
    for y=1:dataIN.years
        Pgas_group_avg_reset = Pgas_group_avg_reset + Pgas_group{i}(y,:);
    end
    dataOUT.Pgas_group_avg{i}=Pgas_group_avg_reset/dataIN.years; %Generacion media anual de cada grupo de microgas turbines
    
end

for i=1:other_count
    
    Pother_reset = zeros(1,8760);
    
    for j = 1:n_other(i)
        Pother_individual_avg_reset=zeros(1,8760);
        Pother_individual_avg_reset = Pother_individual_avg_reset + Pother_individual{i}{j}(dataIN.years,:);
        Pother_individual_avg{i}(j,:)=Pother_individual_avg_reset/dataIN.years; %Generacion media anual de cada generador other
        Pother_reset = Pother_reset + Pother_individual{i}{j}(dataIN.years,:);
        Pother_group{i}(dataIN.years,:) = Pother_reset;    %Generacion anual de cada grupo de generadores other
    end
    
    Pother_group_avg_reset=zeros(1,8760);
    for y=1:dataIN.years
        Pother_group_avg_reset = Pother_group_avg_reset + Pother_group{i}(y,:);
    end
    dataOUT.Pother_group_avg{i}=Pother_group_avg_reset/dataIN.years; %Generacion media anual de cada grupo de generadores other
    
end


Pconventional_reset = zeros(1,8760);

for i = 1:fuel_count
    Pconventional_reset = Pconventional_reset + Pfuel_group{i}(dataIN.years,:);
end
for i = 1:gas_count
    Pconventional_reset = Pconventional_reset + Pgas_group{i}(dataIN.years,:);
end
for i = 1:other_count
    Pconventional_reset = Pconventional_reset + Pother_group{i}(dataIN.years,:);
end

Pconventional(dataIN.years,:) = Pconventional_reset;

%% RELIABILITY ANALYSIS

Ebalance = Egrid(dataIN.years,:);
hours_n_s = 0;
    
    for w=1:8760
        
       if ( Ebalance(w) < 0 )
           E_n_s(w) = - Ebalance(w);               %Energy not supplied
           hours_n_s = hours_n_s + 1;              %hours not supplied
       else
           E_n_s(w) = 0;
       end

    end
    
    E_not_supplied{dataIN.years} = E_n_s;                             %Energy not supplied in year i
    LOEE(dataIN.years) = sum(E_n_s);                                  %Expected Energy not supplied in year i in (kWh/year)    / Loss of energy expectation
    LOLE(dataIN.years) = hours_n_s;                                   %Loss of Load expectation (h/year) = LOLF for this case.....
    MIOP(dataIN.years) = (8760-LOLE(dataIN.years))/8760;              %Yearly Microgrid Islanded Operation probability (p.u.)
    ILSE(dataIN.years) = LOEE(dataIN.years)/LOLE(dataIN.years);       %Island Load Shedding Expectation (kW/ocurrence)- the average kW load that is shed during each interruption in the islanded mode
     
            
dataOUT.LOEE=LOEE;
dataOUT.LOLE=LOLE;
dataOUT.MIOP=MIOP;
dataOUT.ILSE=ILSE;
  
reliability_indexes();
tolerancia=dataOUT.coefLOEE(dataIN.years);       %seleccionar el coeficiente del indice seleccionado     
disp('TOLERANCIA');
disp(tolerancia);
var = var + 8760;

end

%% Calulate Average Anual value of Egrid
dataOUT.Egrid_avg=zeros(1,8760);
for i = 1:dataIN.years
dataOUT.Egrid_avg = dataOUT.Egrid_avg + Egrid(i,:);
end

dataOUT.Egrid_avg = dataOUT.Egrid_avg/dataIN.years;

%% CALCULAR MEDIAS DE GENERACION RENOVABLE, CONVENCIONAL Y BATERIA, BUILDING PROFILE
dataOUT.Prenewables_avg = zeros(1,8760);
dataOUT.Pconventional_avg = zeros(1,8760);
dataOUT.Ebattery_avg = zeros(1,8760);
dataOUT.Pgen_avg = zeros(1,8760);
dataOUT.Building_profile_avg = zeros(1,8760);

for i = 1:dataIN.years
dataOUT.Prenewables_avg = dataOUT.Prenewables_avg + Prenewables(i,:);
dataOUT.Pconventional_avg = dataOUT.Pconventional_avg + Pconventional(i,:);
dataOUT.Ebattery_avg = dataOUT.Ebattery_avg + E(i,:);
dataOUT.Pgen_avg = dataOUT.Pgen_avg + Pgen(i,:);
dataOUT.Building_profile_avg = dataOUT.Building_profile_avg + dataOUT.building_profile(i,:);
end

dataOUT.Prenewables_avg = dataOUT.Prenewables_avg/dataIN.years;
dataOUT.Pconventional_avg = dataOUT.Pconventional_avg/dataIN.years;
dataOUT.Ebattery_avg = dataOUT.Ebattery_avg/dataIN.years;
dataOUT.Pgen_avg = dataOUT.Pgen_avg/dataIN.years;
dataOUT.Building_profile_avg = dataOUT.Building_profile_avg/dataIN.years;

%% Guardando datos de salida
save('datos.mat','dataIN','dataOUT');
disp('SIMULACIÓN COMPLETADA.');
disp('CONSULTAR datos.mat');
