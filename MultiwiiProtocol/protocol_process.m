function [ACK,STATE] = protocol_process( byte,STATE )
%PROTOCOL_PROCESS Parses the received data

persistent inBuf checksum cmdMSP c_state offset dataSize BOARD
if(isempty(checksum))
    inBuf = [];
    checksum = 0;
    cmdMSP = 0;
    c_state = 0;
    offset = 0;
    dataSize = 0;
    BOARD = 'M';
end

byte = uint8(byte);
ACK = 0;

%Follows the Multiwii implementation in protocol.cpp. Adapted for use with
%a RELAY board.
switch c_state
 case 0 %IDLE
    if(byte=='$'), c_state=1; end
 case 1 %HEADER_START
    if(byte=='M' || byte == 'R')
        c_state=2;
        BOARD = byte;
    else
        c_state=0;
    end
 case 2 %HEADER_M
    if(byte=='>')
        c_state=3;
    else
        c_state=0;
    end
 case 3 %HEADER_ARROW
     %We are now expecting the payload size
     dataSize = byte;
     checksum = 0;
     offset = 0;
     inBuf = [];
     checksum = bitxor(checksum,byte);
     c_state = 4;
 case 4 %HEADER_SIZE 
     %Command ID
     cmdMSP = byte;
     checksum = bitxor(checksum,byte);
     c_state = 5;
 case 5 %HEADER_CMD
     if(offset < dataSize)
         inBuf = [inBuf byte];
         checksum = bitxor(checksum,byte);
         offset = offset + 1;
     else
         if(checksum == byte) %Compare calculated and transferred checksum
             if(BOARD == 'R')
                cmdMSP = cast(cmdMSP,'double')+1000;
             end
             STATE = protocol_update_state(cmdMSP, inBuf, STATE, BOARD);
             ACK = cmdMSP;
         end
         c_state = 0;
     end
 otherwise
    c_state = 0;
end

end

