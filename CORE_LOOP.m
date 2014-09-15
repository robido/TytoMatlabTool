function [STATE CYCLE] = CORE_LOOP( serConn, STATE )
%Update the state using serial comm and protocol functions

persistent last_ACK time_last
if(isempty(last_ACK))
    last_ACK = 101;
    time_last = now;
end

%Get all received data until now
send_next = 0;
CYCLE = 0;
while(serConn.BytesAvailable()>0)
    byte = fread(serConn,1,'uchar');
    [ACK, STATE] = protocol_process(byte, STATE);
    if(ACK ~= 0 && ACK==last_ACK)
        %ACK received, send the next command
        send_next = 1;
        while(serConn.BytesAvailable()>0)
            fread(serConn,1,'uchar'); %Empty the buffer if not.
        end
    end
end

seconds_since_last = 24*3600*(now-time_last);
if(send_next == 1 || seconds_since_last>0.2) %Timeout value
    if(send_next~=1)
        disp('RX_TIMOUT');
    else
        %Change command ID
        if(last_ACK == 101)
            last_ACK = 254;
        else
            last_ACK = 101;
            CYCLE = 1;
        end
    end   
   
    COMMAND = protocol_get_command(last_ACK);
    serial_send_bytes(serConn,COMMAND);
    time_last = now;
end

end

