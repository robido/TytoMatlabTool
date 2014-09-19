function plot_values = protocol_get_plot_values(STATE,Plot_Selections)

PLOT_LIST = protocol_get_plot_list();

plot_values = [0 0 0];
number_of_selections = size(Plot_Selections,2);
for i=1:min(3,number_of_selections) %Max of 3 plots
    ID = PLOT_LIST{Plot_Selections(i)}.ID;
    ITEM = PLOT_LIST{Plot_Selections(i)}.ITEM;
    plot_values(i) = protocol_get_value(STATE, ID, ITEM);
end

end

