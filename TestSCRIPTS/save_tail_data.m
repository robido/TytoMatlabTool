function save_tail_data( DATA,YAW_MIN,YAW_MAX )
%SAVE_TAIL_DATA Summary of this function goes here
%   Detailed explanation goes here

%Make the header
TABLE{1,1}='Tail test data';
TABLE{3,1}='Motor:';
TABLE{4,1}='ESC:';
TABLE{5,1}='ESC config/firmware:';
TABLE{6,1}='Blade:';
TABLE{7,1}='MATLAB commit version:';
TABLE{8,1}='Relay board commit version:';
TABLE{9,1}='Nanowii commit version:';
TABLE{10,1}='Comment:';
TABLE{12,1}='RC_YAW';
TABLE{12,2}='VBat (V)';
TABLE{12,3}='Current (mA)';
TABLE{12,4}='Torque (mN·m)';

%Make the data
YAW = DATA.Result.YAW;
AvgTorque = DATA.Result.AvgTorque;
AvgCurrent = DATA.Result.AvgCurrent;
AvgVBAT = DATA.Result.AvgVBAT;
for i=1:numel(YAW)
    TABLE{i+12,1}=YAW(i);
    TABLE{i+12,2}=AvgVBAT(i);
    TABLE{i+12,3}=AvgCurrent(i);
    TABLE{i+12,4}=AvgTorque(i);
end

%Get file to save
filename = 0;
pathname = 0;
while(isequal(filename,0) || isequal(pathname,0))
    [filename, pathname] = uiputfile('*.xls','Pick a location for saving the data.');
    [pathstr,name,ext] = fileparts([pathname filename]);
end

%Save to an excel file
xlswrite([pathstr '\' name ext],TABLE);

%Make current/torque vs rc signal
figure1 = figure;
axes1 = axes('Parent',figure1)
hold(axes1,'all');
[AX,H1,H2] = plotyy(YAW,AvgCurrent,YAW,AvgTorque);
title(['Tail motor current and torque for ' filename '.']);
xlabel('RC YAW Signal (ms)');
set(get(AX(1),'Ylabel'),'String','Current (mA)') 
set(get(AX(2),'Ylabel'),'String','Torque (mN·m)') 
set(H1,'LineStyle','--')
set(H2,'LineStyle',':')
set(H1,'Marker','.')
set(H2,'Marker','.')
saveas(figure1,[pathstr '\' name 32 '- current and torque.fig'])
saveas(figure1,[pathstr '\' name 32 '- current and torque.png'])
saveas(figure1,[pathstr '\' name 32 '- current and torque.pdf'])

%Make torque vs current curve
figure1 = figure;
axes1 = axes('Parent',figure1)
hold(axes1,'all');
plot(AvgTorque,AvgCurrent,'LineStyle','--','Marker','.');
title(['Tail motor torque vs current for ' filename '.']);
xlabel('Torque (mN·m)');
ylabel('Current (mA)');
saveas(figure1,[pathstr '\' name 32 '- torque vs current.fig'])
saveas(figure1,[pathstr '\' name 32 '- torque vs current.png'])
saveas(figure1,[pathstr '\' name 32 '- torque vs current.pdf'])
end

