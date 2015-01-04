%% %%%%Makes a table summarizing the results

clc;
%clear all;

%SET OPTIONS
mesh_size = 300;


%% Get all the files to process
%path = 'D:\Dropbox\Charles Dominic\Technical\Trust Test Jig\Test Results\Main\TestsV2';
path = 'E:\Dropbox\Charles Dominic\Technical\Trust Test Jig\Test Results\Main\TestsV2';

delete([path '\Plots\*.*']); %delete existing plots

old_folder = cd([path '\CSV']);
csv_files = dir('*.csv');
cd(old_folder);

COMPLETE_DATA = {};
TRUSTs = [];
RPMs = [];
TORQUEs = [];
MOTORs = {};
BLADEs = {};
RATIOs = [];

%Get data for all the files
for file_num = 1:numel(csv_files)
    FILEDATA = [];
    
    %Gets the complete test data labelled as DONE into array
    filename = [path '\CSV\' csv_files(file_num,1).name];
    fileID = fopen(filename);
    index = 0;
    line = 0;
    is_table = 0;
    number_read = 0;
    RATIOs(file_num) = 1;

    %Parse the whole file
    while(line~=-1)
        %Read whole line
        index = index + 1;
        line = fgetl(fileID);
        if(~isempty(line))
            if(line~=-1)
                %STATUS:1  Date:2	Time:3	THROTTLE:4	PITCH:5	RPM:6	Trust:7	
                %Torque:8	Vbat:9	Current:10	AmbientTemp:11  MotorTemp:12
                if(is_table==0)
                    %Find the header row
                    DATA = textscan(line,'%s %s','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'Motor:'))
                        MOTORs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'Ratio:'))
                        RATIOs(file_num) = DATA{1,2}(1);
                    end
                    if(strcmp(DATA{1,1}{1,1},'Blade:'))
                        BLADEs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'STATUS'))
                        is_table = 1;
                    end
                else
                    %Check if status is DONE
                    DATA = textscan(line,'%s %s %s %f %f %f %f %f %f %f %f %f','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'DONE'))
                        %Save data
                        vals = [];
                        for i=4:12
                            vals = [vals DATA{1,i}(1)];
                        end
                        FILEDATA = [FILEDATA; vals];
                        TORQUEs = [TORQUEs vals(5)];
                        TRUSTs = [TRUSTs vals(4)];
                        RPMs = [RPMs vals(3)];
                    end
                end
            end
        end
    end
    
    fclose(fileID);
    if(isempty(FILEDATA))
        msgbox(['Something is wrong with' 32 filename '. Maybe it is missing a header?']);
    end
    COMPLETE_DATA{file_num}=FILEDATA;
    
    TORQUEs = unique(sort(TORQUEs));
    TRUSTs = unique(sort(TRUSTs));
    RPMs = unique(sort(RPMs));
end

UniqueMotors = unique(sort(MOTORs));
UniqueBlades = unique(sort(BLADEs));
if(max(strcmp('',UniqueMotors))>0)
    msgbox('ERROR: some tests are missing motor identifier');
end
if(max(strcmp('',UniqueBlades))>0)
    msgbox('ERROR: some tests are missing blade identifier');
end

%Sort by blade alphabetically
[~,ORDER]=sort(BLADEs);

%% Make motors efficiency maps
rpm_mesh = RPMs(1):(RPMs(numel(RPMs))-RPMs(1))/(mesh_size-1):RPMs(numel(RPMs));
trust_mesh = TRUSTs(1):(TRUSTs(numel(TRUSTs))-TRUSTs(1))/(mesh_size-1):TRUSTs(numel(TRUSTs));
torques_mesh = TORQUEs(1):(TORQUEs(numel(TORQUEs))-TORQUEs(1))/(mesh_size-1):TORQUEs(numel(TORQUEs));
for motor = 1:numel(UniqueMotors)
    figh = figure('Visible','Off');
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
            Ratio = RATIOs(i);
            for j=1:size(DATA,1)
                %Get variables
                current = DATA(j,7); %mA
                voltage = DATA(j,6); %V
                torque = DATA(j,5)/Ratio; %mNm
                rpm = DATA(j,3)*Ratio; %RPM
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
    [qx,qy]=meshgrid(rpm_mesh,torques_mesh);
    qz = F(qx,qy);
    contourf(qx,qy,qz);
    colormap jet
    colorbar
    caxis([0.3, 1]);
    %hold on;
    %plot(rpms,torques,'o');
    xlabel('Motor speed (rpm)');
    ylabel('Motor torque (mNm)');
    title(strcat('Efficiency map for motor',32,current_motor,'.',10,13,'Max efficiency of',32,num2str(max_efficiency,2),' at',32,num2str(round(rpm_at_max_eff)),'rpm and',32,num2str(torque_at_max_eff,3),'mNm torque.'));
    saveas(figh,[path '\Plots\Motor',32,current_motor,32,'efficiency map.fig']);
    saveas(figh,[path '\Plots\Motor',32,current_motor,32,'efficiency map.png']);
    saveas(figh,[path '\Plots\Motor',32,current_motor,32,'efficiency map.pdf']);
    close(figh);
end


%% Make blades efficiency maps
for blade = 1:numel(UniqueBlades)
    figh = figure('Visible','Off');
    current_blade = UniqueBlades{blade};
    max_efficiency = 0;
    rpm_at_max_eff = 0;
    trust_at_max_eff = 0;
    trusts = [];
    rpms = [];
    torques = [];
    efficiencies = [];
    for i=1:numel(COMPLETE_DATA)
        if(strcmp(current_blade,BLADEs{i}))
            DATA = COMPLETE_DATA{1,i};
            for j=1:size(DATA,1)
                %Get variables
                trust = DATA(j,4); %g
                rpm = DATA(j,3); %RPM
                torque = DATA(j,5); %mNm
                w = 2*pi*rpm/60; %rad/s

                %Efficiency calc.
                in_power = 0.001*torque*w;
                efficiency = trust/in_power; %g/w
                
                %Save result
                    trusts = [trusts;trust];
                    rpms = [rpms;rpm];
                    efficiencies = [efficiencies;efficiency];
                    torques = [torques;torque];
                    if(efficiency > max_efficiency)
                        max_efficiency = efficiency;
                        rpm_at_max_eff = rpm;
                        trust_at_max_eff = trust;
                    end
            end
        end
    end
    
    %Generate efficiency map for each blade
    F_bladeEff_rpm_torques{blade}=TriScatteredInterp([rpms,torques],efficiencies);
    F_torque_rpm_trust{blade}=TriScatteredInterp([rpms,trusts],torques);
    F_bladeEff_rpm_trust{blade}=TriScatteredInterp([rpms,trusts],efficiencies);
    
    %Plot
    [qx,qy]=meshgrid(rpm_mesh,trust_mesh);
    F = F_bladeEff_rpm_trust{blade};
    qz = F(qx,qy);
    contourf(qx,qy,qz);
    colormap jet
    colorbar
    caxis([5, 60]);
    %hold on;
    %plot(rpms,trusts,'o');
    xlabel('Speed (rpm)');
    ylabel('Trust (grams)');
    title(strcat('Efficiency map for blade',32,current_blade,'.',10,13,'Max efficiency of',32,num2str(max_efficiency,3),'g/w at',32,num2str(round(rpm_at_max_eff)),'rpm and',32,num2str(trust_at_max_eff,3),'g trust.'));
    saveas(figh,[path '\Plots\Blade',32,current_blade,32,'efficiency map.fig']);
    saveas(figh,[path '\Plots\Blade',32,current_blade,32,'efficiency map.png']);
    saveas(figh,[path '\Plots\Blade',32,current_blade,32,'efficiency map.pdf']);
    close(figh);
end

%% Create the combined efficiency maps
TRUST_RESULTS = 75:25:300;
GEAR_RATIOS = [1 1.5 2 2.5 3 5];
test_qty = numel(TRUST_RESULTS)*numel(GEAR_RATIOS);
combinations = numel(GEAR_RATIOS)*numel(UniqueMotors)*numel(UniqueBlades);
best_efficiencies = zeros(1,test_qty);
best_rpms = zeros(1,test_qty);
best_motors = char(zeros(1,test_qty));
best_blades = char(zeros(1,test_qty));
PLOTnum = 1;
for gear = 1:numel(GEAR_RATIOS)
    RATIO = GEAR_RATIOS(gear);
    for motor = 1:numel(UniqueMotors)
        F_motor = F_rpm_torque{motor};
        for blade = 1:numel(UniqueBlades)
            %Calculate combined efficiency map
            F1 = F_bladeEff_rpm_torques{blade};
            [qx,qy]=meshgrid(rpm_mesh,torques_mesh);
            MOT_EFF = F_motor(RATIO*qx,qy/RATIO);
            BLADE_EFF = F1(qx,qy);
            TOTAL_EFF = MOT_EFF.*BLADE_EFF;

            %Plot efficiency map
            figh=figure('Visible','Off');
            contourf(qx,qy,TOTAL_EFF);
            colormap jet
            colorbar
            caxis([5, 20]);
            hold on;
            xlabel('Speed (rpm)');
            ylabel('Torque (mNm)');
            title(strcat('Ratio ',num2str(RATIO),'. Blade',32,UniqueBlades{blade},'. Motor',32,UniqueMotors{motor},'.'));

            iplus = (gear-1)*numel(TRUST_RESULTS);
            for i=1:numel(TRUST_RESULTS)
                %Get data for specific trust
                trust_line = TRUST_RESULTS(i);
                F2 = F_torque_rpm_trust{blade};
                tx = F2(rpm_mesh,trust_line*ones(size(rpm_mesh)));
                mot_eff_at_trust = F_motor(RATIO*rpm_mesh,tx/RATIO);
                blade_eff_at_trust = F1(rpm_mesh,tx);
                total_eff_at_trust = mot_eff_at_trust.*blade_eff_at_trust;
                tx(isnan(total_eff_at_trust))=NaN; %remove from tx elements that the motor cannot handle
                [max_eff index_max_eff] = max(total_eff_at_trust);
                rpm_of_max_eff = rpm_mesh(index_max_eff);
                torque_of_max_eff = tx(index_max_eff);

                %Check if best
                if(best_efficiencies(i+iplus)<max_eff)
                    best_efficiencies(i+iplus) = max_eff;
                    best_rpms(i+iplus) = rpm_of_max_eff;
                    best_motors(i+iplus) = UniqueMotors{motor};
                    best_blades(i+iplus) = UniqueBlades{blade};
                end

                %Plot line for this trust   
                plot(rpm_mesh,tx,'r');
                plot(rpm_of_max_eff,torque_of_max_eff,'o','MarkerFaceColor','g','MarkerSize',5);
                text(rpm_of_max_eff,torque_of_max_eff,[num2str(trust_line) 'g' 10 13 32], 'HorizontalAlignment','left','FontSize',12)
            end  
            
            saveas(figh,[path '\Plots\Combination ','Ratio ',num2str(RATIO),' Motor',32,UniqueMotors{motor},' Blade',32,UniqueBlades{blade},'.fig']);
            saveas(figh,[path '\Plots\Combination ','Ratio ',num2str(RATIO),' Motor',32,UniqueMotors{motor},' Blade',32,UniqueBlades{blade},'.png']);
            saveas(figh,[path '\Plots\Combination ','Ratio ',num2str(RATIO),' Motor',32,UniqueMotors{motor},' Blade',32,UniqueBlades{blade},'.pdf']);
            close(figh);
        end
    end
end

%% Present the results
clear DISPLAY
DISPLAY{1,1}='Trust (g)';
DISPLAY{1,2}='Gearing';
DISPLAY{1,3}='Sugg. Motor';
DISPLAY{1,4}='Sugg. Blade';
DISPLAY{1,5}='Sugg. Blade RPM';
DISPLAY{1,6}='Expected Eff. (g/w)';
display_line = 2;
for gear = 1:numel(GEAR_RATIOS)
    iplus = (gear-1)*numel(TRUST_RESULTS);
    for i=1:numel(TRUST_RESULTS)
        if(best_rpms(i+iplus)>0)
            DISPLAY{display_line,1}=TRUST_RESULTS(i);
            DISPLAY{display_line,2}=GEAR_RATIOS(gear);
            DISPLAY{display_line,3}=best_motors(i+iplus);
            DISPLAY{display_line,4}=best_blades(i+iplus);
            DISPLAY{display_line,5}=best_rpms(i+iplus);
            DISPLAY{display_line,6}=best_efficiencies(i+iplus);
            display_line = display_line+1;
        end
    end
end
disp(DISPLAY);
cell2csv([path '\PredictionsV2.csv'],DISPLAY);

msgbox('DONE');