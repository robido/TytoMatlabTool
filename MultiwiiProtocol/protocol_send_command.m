function protocol_send_command( PORT,LastAck )
% Sends the next command in line
serial_send_bytes(PORT,protocol_get_next_command(LastAck)); %Keep alive
end

