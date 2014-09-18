function PLOT_LIST = protocol_get_plot_list( input_args )
%Returns the list of items that can be plotted, the required ID, and the
%function to get this value

PLOT_LIST{1}.NAME = 'Cycle time (us)';
PLOT_LIST{1}.ID = 101;

PLOT_LIST{2}.NAME = 'Debug 1';
PLOT_LIST{2}.ID = 254;

PLOT_LIST{3}.NAME = 'Debug 2';
PLOT_LIST{3}.ID = 254;

PLOT_LIST{4}.NAME = 'Debug 3';
PLOT_LIST{4}.ID = 254;

PLOT_LIST{5}.NAME = 'Debug 4';
PLOT_LIST{5}.ID = 254;

end

