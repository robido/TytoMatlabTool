function STATE = protocol_update_state( cmdMSP, inBuf, STATE )
%PROTOCOL_UPDATE_STATE

[DEF_VAL DEF_STRING DEF_SIZE] = protocol_import_DEF();

byte_counter = 1;
for i=1:DEF_SIZE
    ID = DEF_VAL(i,1);
    if(ID == cmdMSP)
        ITEM = DEF_VAL(i,2);
        if(ITEM == 0)
           %Save the command name
           CELL_IDENT = DEF_STRING{i,1};
        else
           %Get the value to save
           VALUE_IDENT = DEF_STRING{i,1};
           TYPE = DEF_STRING{i,4};
           Value = 0;
           if(strcmp(TYPE,'uint16')||strcmp(TYPE,'int16'))
              Value = typecast(inBuf(byte_counter:byte_counter+1),TYPE);
              byte_counter = byte_counter + 2;
           end 
           EVAL_STR = strcat('STATE.M.',CELL_IDENT,'.',VALUE_IDENT,'=Value;');
           eval(EVAL_STR); %Save into state variable.
        end
        
    end
end