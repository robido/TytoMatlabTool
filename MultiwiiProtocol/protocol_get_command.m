function [ COMMAND ] = protocol_get_command(cmd)

COMMAND = [];
if(cmd~=0)
    COMMAND = ['$' 'M' '<' 0 cmd cmd];
end

end

