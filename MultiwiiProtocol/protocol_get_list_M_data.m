function M_DATA = protocol_get_list_M_data()
%returns the list of displayable data and their codes for the Multiwii
%(Heli)
[DEF_VAL DEF_STRING DEF_SIZE] = protocol_import_DEF();

count = 1;
for i=1:DEF_SIZE
    NAME = DEF_STRING{i,7};
    DISPLAY = DEF_VAL(i,4);
    ID = DEF_VAL(i,1);
    if(DISPLAY)
        M_DATA{count}.NAME = NAME;
        M_DATA{count}.ID = ID;
        count = count+1;
    end
end

end

