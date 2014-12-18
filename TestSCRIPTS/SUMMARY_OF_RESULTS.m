%%%%%%Makes a table summarizing the results

clc;
clear all;

%Remove specific warnings


%% Get all the files to process
path = 'D:\Dropbox\Charles Dominic\Technical\Trust Test Jig\Test Results\Main';
%path = 'E:\Dropbox\Charles Dominic\Technical\Trust Test Jig\Test Results\Main';

old_folder = cd([path '\Tests']);
csv_files = dir('*.csv');
cd(old_folder);

COMPLETE_DATA = {};
TRUSTs = [];
RPMs = [];
MOTORs = {};
BLADEs = {};

%Get data for all the files
for file_num = 1:numel(csv_files)
    FILEDATA = [];
    
    %Gets the complete test data labelled as DONE into array
    filename = [path '\Tests\' csv_files(file_num,1).name];
    fileID = fopen(filename);
    index = 0;
    line = 0;
    is_table = 0;
    number_read = 0;

    %Parse the whole file
    while(line~=-1)
        %Read whole line
        index = index + 1;
        line = fgetl(fileID);
        if(~isempty(line))
            if(line~=-1)
                %   1       2           3        4        5      6    7        
                %STATUS	TargetRPM	TargetTrust	Date	Time	RPM	Trust	
                %   8     9        10        11         12          13       14
                %Torque	Vbat	Current	AmbientTemp	MotorTemp	THROTTLE	PITCH
                if(is_table==0)
                    %Find the header row
                    DATA = textscan(line,'%s %s','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'Motor:'))
                        MOTORs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'Blade:'))
                        BLADEs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'STATUS'))
                        is_table = 1;
                    end
                else
                    %Check if status is DONE
                    DATA = textscan(line,'%s %f %f %s %s %f %f %f %f %f %f %f %f %f','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'DONE'))
                        %Save data
                        vals = [DATA{1,2}(1),DATA{1,3}(1)];
                        for i=6:14
                            vals = [vals DATA{1,i}(1)];
                        end
                        FILEDATA = [FILEDATA; vals];
                        TRUSTs = [TRUSTs DATA{1,3}(1)];
                        RPMs = [RPMs DATA{1,2}(1)];
                    end
                end
            end
        end
    end
    
    fclose(fileID);
    COMPLETE_DATA{file_num}=FILEDATA;
end

%Get the list of trusts
TRUSTs = unique(sort(TRUSTs));
RPMs = unique(sort(RPMs));
UniqueMotors = unique(sort(MOTORs));
UniqueBlades = unique(sort(BLADEs));

%Sort by blade alphabetically
[~,ORDER]=sort(BLADEs);

%% For each test, and each trust, get the best efficiency in w/g
DISPLAY{1,1}='g/w';
DISPLAY{1,2}='Motor';
DISPLAY{1,3}='Blade';
for order_num=1:numel(COMPLETE_DATA)
    test_num = ORDER(order_num);
    [pathstr, name, ext] = fileparts(csv_files(test_num,1).name);
    DISPLAY{order_num+1,1} = name;
    DISPLAY{order_num+1,2} = MOTORs{test_num};
    DISPLAY{order_num+1,3} = BLADEs{test_num};
    for trust = 1:numel(TRUSTs)
        DISPLAY{1,trust+3}=strcat(num2str(TRUSTs(trust)),'g');
        DATA = COMPLETE_DATA{1,test_num};
        
        %Only keep the lines for current trust
        DATA(DATA(:,2)~=TRUSTs(trust),:)=[];
        
        %Get the watts/g
        trustvals = DATA(:,4);
        voltages = DATA(:,6);
        currents = DATA(:,7)*0.001;
        efficiency = trustvals./(voltages.*currents);
        
        DISPLAY{order_num+1,trust+3}=max(efficiency);
    end
end
disp(DISPLAY);
cell2csv([path '\Summary.csv'],DISPLAY);


%% Make motors efficiency maps
numelems = 300;
rpmrange = RPMs;
trustrange = TRUSTs;
figure(1);
title('Efficiency maps for the motors');
set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
rows = floor(sqrt(numel(UniqueMotors)));
columns = ceil(numel(UniqueMotors)/rows);
for motor = 1:numel(UniqueMotors)
    subplot(rows,columns,motor);
    current_motor = UniqueMotors{motor};
    max_efficiency = 0;
    rpm_at_max_eff = 0;
    torque_at_max_eff = 0;
    torques = [];
    rpms = [];
    efficiencies = [];
    for i=1:numel(COMPLETE_DATA)
        if(strcmp(current_motor,MOTORs{i}))
            DATA = COMPLETE_DATA{1,i};
            for j=1:size(DATA,1)
                %Get variables
                current = DATA(j,7); %mA
                voltage = DATA(j,6); %V
                torque = DATA(j,5); %mNm
                rpm = DATA(j,1); %RPM
                w = 2*pi*rpm/60; %rad/s

                %Efficiency calc.
                in_power = 0.001*current*voltage;
                out_power = 0.001*torque*w;
                efficiency = out_power/in_power;
                
                %Save result
                    torques = [torques;torque];
                    rpms = [rpms;rpm];
                    efficiencies = [efficiencies;efficiency];
                    if(efficiency > max_efficiency)
                        max_efficiency = efficiency;
                        rpm_at_max_eff = rpm;
                        torque_at_max_eff = torque;
                    end
            end
        end
    end
    
    %Generate efficiency map for each motor
    F = TriScatteredInterp([rpms,torques],efficiencies);
    F_rpm_torque{motor}=F;
    
    %Plot
    minrpm = rpmrange(1);
    maxrpm = rpmrange(numel(rpmrange));
    mintorque = min(torques);
    maxtorque = max(torques);
    [qx,qy]=meshgrid(minrpm:(maxrpm-minrpm)/numelems:maxrpm,mintorque:(maxtorque-mintorque)/numelems:maxtorque);
    qz = F(qx,qy);
    contourf(qx,qy,qz);
    colormap jet
    colorbar
    hold on;
    plot(rpms,torques,'o');
    xlabel('Motor speed (rpm)');
    ylabel('Motor torque (mNm)');
    title(strcat('Efficiency map for motor',32,current_motor,'.',10,13,'Max efficiency of',32,num2str(max_efficiency,2),' at',32,num2str(round(rpm_at_max_eff)),'rpm and',32,num2str(torque_at_max_eff,3),'mNm torque.'));
end

%% Make blades efficiency maps
figure(2);
title('Efficiency maps for the blades');
set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
rows = floor(sqrt(numel(UniqueBlades)));
columns = ceil(numel(UniqueBlades)/rows);
for blade = 1:numel(UniqueBlades)
    subplot(rows,columns,blade);
    current_blade = UniqueBlades{blade};
    max_efficiency = 0;
    rpm_at_max_eff = 0;
    trust_at_max_eff = 0;
    trusts = [];
    rpms = [];
    efficiencies = [];
    for i=1:numel(COMPLETE_DATA)
        if(strcmp(current_blade,BLADEs{i}))
            DATA = COMPLETE_DATA{1,i};
            for j=1:size(DATA,1)
                %Get variables
                trust = DATA(j,2); %g
                rpm = DATA(j,1); %RPM
                torque = DATA(j,5); %mNm
                w = 2*pi*rpm/60; %rad/s

                %Efficiency calc.
                in_power = 0.001*torque*w;
                efficiency = trust/in_power; %g/w
                
                %Save result
                    trusts = [trusts;trust];
                    rpms = [rpms;rpm];
                    efficiencies = [efficiencies;efficiency];
                    if(efficiency > max_efficiency)
                        max_efficiency = efficiency;
                        rpm_at_max_eff = rpm;
                        trust_at_max_eff = trust;
                    end
            end
        end
    end
    
    %Generate efficiency map for each blade
    F = TriScatteredInterp([rpms,trusts],efficiencies);
    F_rpm_trust{blade}=F;
    
    %Plot
    minrpm = rpmrange(1);
    maxrpm = rpmrange(numel(rpmrange));
    mintrust = min(trustrange);
    maxtrust = max(trustrange);
    [qx,qy]=meshgrid(minrpm:(maxrpm-minrpm)/numelems:maxrpm,mintrust:(maxtrust-mintrust)/numelems:maxtrust);
    qz = F(qx,qy);
    contourf(qx,qy,qz);
    colormap jet
    colorbar
    hold on;
    plot(rpms,trusts,'o');
    xlabel('Speed (rpm)');
    ylabel('Trust (grams)');
    title(strcat('Efficiency map for blade',32,current_blade,'.',10,13,'Max efficiency of',32,num2str(max_efficiency,3),'g/w at',32,num2str(round(rpm_at_max_eff)),'rpm and',32,num2str(trust_at_max_eff,3),'g trust.'));
end

%% Create the combined efficiency maps
Best_blades = char(zeros(numel(TRUSTs),1));
Best_motors = char(zeros(numel(TRUSTs),1));
Best_efficiencies = 0*TRUSTs;
Best_rpms = 0*TRUSTs;

for motor = 1:numel(UniqueMotors)
    figure(2+motor);
    F_motor = F_rpm_torque{motor};
    for blade = 1:numel(UniqueBlades)
        
        %Calculate
        F_blade = F_rpm_trust{blade};
        [qx,qy]=meshgrid(rpmrange,trustrange);
        qz = F_blade(qx,qy);
        ws = qx.*(2*pi/60);
        torques = qy./(0.001*qz.*ws);
        effs = F_motor(qx,torques);
        total_effs = effs.*qz;
        
        %Check if best
        for trust=1:numel(trustrange)
            [max_eff,rpm_index] = max(total_effs(trust,:));
            if(max_eff>Best_efficiencies(trust))
                Best_efficiencies(trust) = max_eff;
                Best_rpms(trust) = rpmrange(rpm_index);
                Best_blades(trust) = UniqueBlades{blade};
                Best_motors(trust) = UniqueMotors{motor};
            end
        end
     
        %Plot
        subplot(rows,columns,blade);
        contourf(qx,qy,effs);
        colormap jet
        colorbar
        hold on;
        %plot(rpms,trusts,'x');
        xlabel('Speed (rpm)');
        ylabel('Trust (grams)');
        title(strcat('Blade',32,UniqueBlades{blade},'. Motor',32,UniqueMotors{motor},'.'));
    end
end
%Present the results
clear DISPLAY
DISPLAY{1,1}='Trust (g)';
DISPLAY{1,2}='Sugg. Motor';
DISPLAY{1,3}='Sugg. Blade';
DISPLAY{1,4}='Sugg. RPM';
DISPLAY{1,5}='Expected Eff. (g/w)';
for i=1:numel(Best_blades)
    DISPLAY{1+i,1}=TRUSTs(i);
    DISPLAY{1+i,2}=Best_motors(i);
    DISPLAY{1+i,3}=Best_blades(i);
    DISPLAY{1+i,4}=Best_rpms(i);
    DISPLAY{1+i,5}=Best_efficiencies(i);
end
disp(DISPLAY);
cell2csv([path '\Predictions.csv'],DISPLAY);