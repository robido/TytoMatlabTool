%% CONNECT
[serPORT,serTimer] = serial_setup_open('COM29',115200);
if(serPORT~=0)
   disp('CONNECTED'); 
end

%% CLOSE
serial_close(serPORT,serTimer);
