function PLOT_LIST = protocol_get_plot_list()
%Returns the list of items that can be plotted, the required ID, and the
%function to get this value
i = 1;

%Serial refresh rate
PLOT_LIST{i}.NAME = 'Serial rate (Hz)';
PLOT_LIST{i}.ID = 0;
PLOT_LIST{i}.ITEM = 1;
i=i+1;

%Cycle Time
PLOT_LIST{i}.NAME = 'Cycle time (us)';
PLOT_LIST{i}.ID = 101;
PLOT_LIST{i}.ITEM = 1;
i=i+1;

%Imu data
PLOT_LIST{i}.NAME = 'accSmooth_ROLL';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 1;
i=i+1;
PLOT_LIST{i}.NAME = 'accSmooth_PITCH';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 2;
i=i+1;
PLOT_LIST{i}.NAME = 'accSmooth_YAW';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 3;
i=i+1;
PLOT_LIST{i}.NAME = 'gyroData_ROLL';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 4;
i=i+1;
PLOT_LIST{i}.NAME = 'gyroData_PITCH';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 5;
i=i+1;
PLOT_LIST{i}.NAME = 'gyroData_YAW';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 6;
i=i+1;
PLOT_LIST{i}.NAME = 'magADC_ROLL';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 7;
i=i+1;
PLOT_LIST{i}.NAME = 'magADC_PITCH';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 8;
i=i+1;
PLOT_LIST{i}.NAME = 'magADC_YAW';
PLOT_LIST{i}.ID = 102;
PLOT_LIST{i}.ITEM = 9;
i=i+1;
% PLOT_LIST{i}.NAME = 'gyroADC_ROLL';
% PLOT_LIST{i}.ID = 102;
% i=i+1;
% PLOT_LIST{i}.NAME = 'gyroADC_PITCH';
% PLOT_LIST{i}.ID = 102;
% i=i+1;
% PLOT_LIST{i}.NAME = 'gyroADC_YAW';
% PLOT_LIST{i}.ID = 102;
% i=i+1;
% PLOT_LIST{i}.NAME = 'accADC_ROLL';
% PLOT_LIST{i}.ID = 102;
% i=i+1;
% PLOT_LIST{i}.NAME = 'accADC_PITCH';
% PLOT_LIST{i}.ID = 102;
% i=i+1;
% PLOT_LIST{i}.NAME = 'accADC_YAW';
% PLOT_LIST{i}.ID = 102;
% i=i+1;

%Debug
PLOT_LIST{i}.NAME = 'Debug 1';
PLOT_LIST{i}.ID = 254;
PLOT_LIST{i}.ITEM = 1;
i=i+1;
PLOT_LIST{i}.NAME = 'Debug 2';
PLOT_LIST{i}.ID = 254;
PLOT_LIST{i}.ITEM = 2;
i=i+1;
PLOT_LIST{i}.NAME = 'Debug 3';
PLOT_LIST{i}.ID = 254;
PLOT_LIST{i}.ITEM = 3;
i=i+1;
PLOT_LIST{i}.NAME = 'Debug 4';
PLOT_LIST{i}.ID = 254;
PLOT_LIST{i}.ITEM = 4;
i=i+1;
end

