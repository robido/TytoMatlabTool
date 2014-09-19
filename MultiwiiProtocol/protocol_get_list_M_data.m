function M_DATA = protocol_get_list_M_data()
%returns the list of displayable data and their codes for the Multiwii
%(Heli)
i=1;

M_DATA{i}.NAME='Cycle time, I2C Errors';
M_DATA{i}.ID=101;
i=i+1;

M_DATA{i}.NAME='IMU data';
M_DATA{i}.ID=102;
i=i+1;

M_DATA{i}.NAME='Debug values';
M_DATA{i}.ID=254;
i=i+1;

end

