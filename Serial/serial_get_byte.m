function byte = serial_get_byte( s )
%SERIAL_GET_BYTE Summary of this function goes here
%   Detailed explanation goes here
if(serial_is_available(s)>0)
    byte = fread(s,1);
else
    byte = [];
end

end

