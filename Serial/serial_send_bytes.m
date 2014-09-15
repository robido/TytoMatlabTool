function serial_send_bytes( PORT, BYTES )
%SEND_BYTES Summary of this function goes here
%   Detailed explanation goes here
fwrite(PORT,BYTES,'async');
end

