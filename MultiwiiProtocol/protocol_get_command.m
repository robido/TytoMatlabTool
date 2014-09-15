function [ COMMAND ] = protocol_get_command(cmd)
  
COMMAND = ['$' 'M' '<' 0 cmd cmd];

end

