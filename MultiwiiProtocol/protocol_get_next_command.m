function [ COMMAND ] = protocol_get_next_command(lastAckVal)
persistent protocolAckRequired
if(isempty(protocolAckRequired))
    protocolAckRequired = 101;
end

if(lastAckVal == protocolAckRequired)
    if(lastAckVal == 101)
        protocolAckRequired = 254; 
    else
        protocolAckRequired = 101;
    end
end
    
COMMAND = ['$' 'M' '<' 0 protocolAckRequired protocolAckRequired];

end

