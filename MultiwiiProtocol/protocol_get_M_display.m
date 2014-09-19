function DISP_string = protocol_get_M_display( STATE, List_of_commands )


[DEF_VAL DEF_STRING DEF_SIZE] = protocol_import_DEF();
DISP_string = [];

size_commands = size(List_of_commands,2);
for i=1:size_commands
    CURRENT_ID = List_of_commands(i);
    for j=1:DEF_SIZE
        ID = DEF_VAL(j,1);
        
        if(ID == CURRENT_ID)
            ITEM = DEF_VAL(j,2);
            DISPLAY_STRING = DEF_STRING{j,7};
            if(ITEM ~= 0)
                VAL = protocol_get_value(STATE, ID, ITEM);
                DISP_string = [DISP_string 32 32 32 32 32 ...
                    DISPLAY_STRING ':' 32 num2str(VAL) 10 13];
            else
                DISP_string = [DISP_string ...
                     DISPLAY_STRING ':' 10 13];
            end
        end
    end
    DISP_string = [DISP_string 10 13];
end