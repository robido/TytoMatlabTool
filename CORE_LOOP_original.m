function [STATE CYCLE] = CORE_LOOP( serConn, captureFile, STATE, LIST_OF_COMMANDS, DELAY_COMP )
%Update the state using serial comm and protocol functions

persistent time_last ACKS bytes_since_last_cycle
if(isempty(time_last))
    time_last = now;
    ACKS = [];
    bytes_since_last_cycle = [];
end

%Get all received data until now
CYCLE = 0;
next_byte = serial_get_byte(captureFile);
bytes_since_last_cycle = [bytes_since_last_cycle next_byte]; %For debug purposes
while(~isempty(next_byte) && ~isequal(LIST_OF_COMMANDS, ACKS))
    [ACK, STATE] = protocol_process(next_byte, STATE);
    if(ACK~=0)
        ACKS = [double(ACKS) double(ACK)];
    end
    next_byte = serial_get_byte(captureFile);
end

%Check that a full report was received
if( min(ismember(LIST_OF_COMMANDS,ACKS)) )
    CYCLE = 1;
    disp('CYCLE COMPLETE');
    bytes_since_last_cycle = [];
end

seconds_since_last = 24*3600*(now-time_last);
if(CYCLE == 1 || seconds_since_last>0.5) %Timeout value
    multiple_command = 0;
    if(CYCLE~=1)
        disp(strcat('RX_TIMOUT. Buffer: ',num2str(bytes_since_last_cycle))); 
        multiple_command = DELAY_COMP; %Compensates for bluetooth transmission delays by sending the next command before the last one is acknowledged.
    end   
    bytes_to_send = [];
    while(multiple_command >= 0)
        for(i=1:size(LIST_OF_COMMANDS,2))
            commandID = LIST_OF_COMMANDS(i);
            bytes_to_send = [bytes_to_send protocol_get_command(commandID,STATE)];
        end
        num_bytes = size(bytes_to_send,2);
        if(num_bytes>=multiple_command)
            multiple_command = -1;
        end
    end

    serial_send_bytes(serConn,bytes_to_send);
    pause(0.5);

    time_last = now;
    ACKS = [];
end

end

