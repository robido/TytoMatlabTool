%% CONNECT
[PORT, serial_tmr_delay] = serial_setup_open('COM3',115200);
if(PORT~=0)
   disp('CONNECTED'); 
end

%% SHOULD BE RUNNING IN INTERRUPT MODE
start(serial_tmr_delay);

%% CLOSE
serial_close(PORT);
