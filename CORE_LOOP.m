function [STATE CYCLE] = CORE_LOOP( serialport, STATE, LIST_OF_COMMANDS, DELAY_COMP )
%Update the state using serial comm and protocol functions

persistent time_last commandQueue
if(isempty(time_last))
    time_last = now-1;
    commandQueue = [];
end

CYCLE = 0;

%Get all received data until next ACK
next_byte = -1;
ACK = 0;
while(~isempty(next_byte) && ACK==0)
    next_byte = serial_get_byte(serialport);
    if(~isempty(next_byte))
        [ACK, STATE] = protocol_process(next_byte, STATE);
    end
end

%Check for timout
seconds_since_last = 24*3600*(now-time_last);
if(seconds_since_last>0.5)
    timout = 1;
    disp('RX_TIMOUT');
else
    timout = 0;
end

%Send the next command
if(ACK~=0 || timout)
    bytes_to_send = [];
    
    %Acknowledge reception
    if(ACK~=0)
        commandQueue(find(commandQueue==ACK,1,'first'))=[];
    end
    
    %Fill the queue from the list of commands
    while(isempty(commandQueue))
        commandQueue = [commandQueue LIST_OF_COMMANDS];
        CYCLE = 1;
    end
    
    %Send next command
    commandID = commandQueue(1);
    bytes_to_send = [bytes_to_send protocol_get_command(commandID,STATE)];
    serial_send_bytes(serialport,bytes_to_send);
    time_last = now;
end

end

