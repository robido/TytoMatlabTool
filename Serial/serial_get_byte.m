function byte = serial_get_byte( serConn )
%SERIAL_GET_BYTE Summary of this function goes here
%   Detailed explanation goes here
byte = fread(serConn, 1, 'uint8');

end

