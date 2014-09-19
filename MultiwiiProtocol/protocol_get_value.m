function VAL = protocol_get_value(STATE, ID, ITEM)

[DEF_VAL DEF_STRING DEF_SIZE] = protocol_import_DEF();

VAL = 0;
for i=1:DEF_SIZE
    cmdMSP = DEF_VAL(i,1);
    if(ID == cmdMSP)
        if(ID<1000)
            if(ID==0)
                CATEGORY = '';
            else
                CATEGORY = 'M.';
            end
        else
            CATEGORY = 'R.';
        end
        ITEMcurr = DEF_VAL(i,2);
        if(ITEMcurr == 0)
           %Save the command name
           CELL_IDENT = DEF_STRING{i,1};
        else
           if(ITEMcurr == ITEM)
               %Get the value
               VALUE_IDENT = DEF_STRING{i,1};
               EVAL_STR = strcat('VAL = STATE.',CATEGORY,CELL_IDENT,'.',VALUE_IDENT,';');
               try
                eval(EVAL_STR);
               catch
               end
           end
        end
        
    end
end

end

