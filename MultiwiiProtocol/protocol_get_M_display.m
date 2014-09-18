function DISP_string = protocol_get_M_display( STATE, List_of_commands )

DISP_string = [];

size_commands = size(List_of_commands,2);
for i=1:size_commands
    ID = List_of_commands(i);
    switch ID
        case 101
            cycleTime = protocol_get_cycleTime(STATE);
            DISP_string = [DISP_string,'cycleTime (us):',32,num2str(cycleTime),10,13];
            DISP_string = [DISP_string,'cycleTime (Hz):',32,num2str(round(1000000/cycleTime)),10,13];
        case 254
            debug = protocol_get_debug(STATE);
            DISP_string = [DISP_string,'debug:',32,num2str(debug),10,13];
    end
end

