function serial_close(PORT)
%SERIAL_CLOSE Summary of this function goes here
%   Detailed explanation goes here
try
    fclose(PORT);
catch
    stopasync(PORT);
    fclose(PORT);
end
disp('COM PORT CLOSED');

end

