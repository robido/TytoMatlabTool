function [ COMMAND ] = protocol_get_command(cmd,STATE)

%OUTPUT COMMAND PARAMETERS
switch cmd
    case 200 %MSP_SET_RAW_RC
        param = cast(STATE.MSP_SET_RAW_RC,'int16');
        PAYLOAD = typecast(param, 'uint8');
    otherwise
        PAYLOAD = [];
end

Payload_size = size(PAYLOAD,2);
checksum = 0;
COMMAND = ['$' 'M' '<']; 
checksum = bitxor(checksum,Payload_size);
COMMAND = [COMMAND Payload_size];

checksum = bitxor(checksum,cmd);
COMMAND = [COMMAND cmd];

%Add payload here
for i=1:Payload_size
    byte_to_add = PAYLOAD(i);
    checksum = bitxor(checksum,byte_to_add);
    COMMAND = [COMMAND byte_to_add];
end

COMMAND = [COMMAND checksum];

end

