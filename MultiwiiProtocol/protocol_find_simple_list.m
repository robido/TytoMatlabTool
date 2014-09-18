function List_of_commands = protocol_find_simple_list( M_Selections, Plot_Selections )

%Get the complete list of commands needed
List_of_commands = [];
M_data = protocol_get_list_M_data();
M_size = size(M_Selections,2);
for i=1:M_size
    selection = M_Selections(i);
    ID = M_data{selection}.ID;
    List_of_commands = [List_of_commands ID];
end

plot_data = protocol_get_plot_list();
plot_size = size(Plot_Selections,2);
for i=1:plot_size
    selection = Plot_Selections(i);
    ID = plot_data{selection}.ID;
    List_of_commands = [List_of_commands ID];
end

%Cleanup the list to remove duplicates and sort
List_of_commands = unique(List_of_commands);

if(isempty(List_of_commands))
    List_of_commands = 101; %Minimal command
end

end

