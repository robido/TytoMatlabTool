function [STATE CYCLE] = CORE_LOOP( serConn, STATE, LIST_OF_COMMANDS, DELAY_COMP )
%Update the state using serial comm and protocol functions

persistent time_last ACKS
if(isempty(time_last))
    time_last = now;
    ACKS = [];
end

%Get all received data until now
CYCLE = 0;
while(serConn.BytesAvailable()>0 && ~isequal(LIST_OF_COMMANDS, ACKS))
    byte = fread(serConn,1,'uchar');
    [ACK, STATE] = protocol_process(byte, STATE);
    if(ACK~=0)
        ACKS = [ACKS ACK];
    end
end

%Check that a full report was received
if(isequal(LIST_OF_COMMANDS, ACKS))
    CYCLE = 1;
end

seconds_since_last = 24*3600*(now-time_last);
if(CYCLE == 1 || seconds_since_last>0.5) %Timeout value
    multiple_command = 0;
    if(CYCLE~=1)
        %disp('RX_TIMOUT'); 
        multiple_command = DELAY_COMP; %Compensates for bluetooth transmission delays by sending the next command before the last one is acknowledged.
    end   
    bytes_to_send = [];
    while(multiple_command >= 0)
        for(i=1:size(LIST_OF_COMMANDS,2))
            commandID = LIST_OF_COMMANDS(i);
            bytes_to_send = [bytes_to_send protocol_get_command(commandID)];
        end
        num_bytes = size(bytes_to_send,2);
        if(num_bytes>=multiple_command)
            multiple_command = -1;
        end
    end

    serial_send_bytes(serConn,bytes_to_send);

    time_last = now;
    ACKS = [];
end

end

