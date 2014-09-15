%% CONNECT
serPORT = serial_setup_open('COM29',115200);
if(serPORT~=0)
   disp('CONNECTED'); 
end
STATE = [];

%% WHAT THE GUI WOULD DO AT TIMER INTERVALS
%Update the state using serial comm and protocol functions
STATE = CORE_LOOP(serPORT,STATE);
    
%Get results
cycleTime = protocol_get_cycleTime(STATE);

%Display
disp(cycleTime);

%% CLOSE
serial_close(serPORT);
