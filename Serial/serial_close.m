function serial_close(PORT)
%SERIAL_CLOSE Summary of this function goes here
%   Detailed explanation goes here
try %try to close any we can in case they are faulty.
  fclose(PORT);  
  disp('COM PORT CLOSED');
catch
end; %try

end

