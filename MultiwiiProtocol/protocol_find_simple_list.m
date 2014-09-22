function List_of_commands = protocol_find_simple_list( M_Selections, Plot_Selections, OTHER_COMMANDS )

%Get the complete list of commands needed to be refreshed on serial port
List_of_commands = OTHER_COMMANDS;
M_data = protocol_get_list_M_data();
M_size = size(M_data,2);
M_selection_size = size(M_Selections,2);

%Get list of allowed commands
ALLOWED = [];
for i=1:M_size
    if(M_data{i}.ID ~= 0)
        ALLOWED = [ALLOWED M_data{i}.ID];
    end
end

for i=1:M_selection_size
    selection = M_Selections(i);
    ID = M_data{selection}.ID;
    if( ismember(ID, ALLOWED) )
        List_of_commands = [List_of_commands ID];
    end
end

plot_data = protocol_get_plot_list();
plot_selection_size = size(Plot_Selections,2);
for i=1:plot_selection_size
    selection = Plot_Selections(i);
    ID = plot_data{selection}.ID;
    if( ismember(ID, ALLOWED) )
        List_of_commands = [List_of_commands ID];
    end
end

%Cleanup the list to remove duplicates and sort.
List_of_commands = unique(List_of_commands);

if(isempty(List_of_commands))
    List_of_commands = 101; %Minimal command
end

end

