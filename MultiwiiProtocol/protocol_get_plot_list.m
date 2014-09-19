function PLOT_LIST = protocol_get_plot_list()
%Returns the list of items that can be plotted, the required ID, and the
%function to get this value

[DEF_VAL DEF_STRING DEF_SIZE] = protocol_import_DEF();

count = 1;
for i=1:DEF_SIZE
    NAME = DEF_STRING{i,7};
    DO_PLOT = DEF_VAL(i,5);
    if(DO_PLOT)
        PLOT_LIST{count}.NAME = NAME;
        PLOT_LIST{count}.ID = DEF_VAL(i,1);
        PLOT_LIST{count}.ITEM = DEF_VAL(i,2);
        count = count+1;
    end
end

