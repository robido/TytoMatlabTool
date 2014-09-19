function plot_names = protocol_get_plot_values(STATE,Plot_Selections)

PLOT_LIST = protocol_get_plot_list();

plot_names = {'No selection','No selection','No selection'};
number_of_selections = size(Plot_Selections,2);
for i=1:min(3,number_of_selections) %Max of 3 plots
    NAME = PLOT_LIST{Plot_Selections(i)}.NAME;
    plot_names{i} = NAME;
end

end

