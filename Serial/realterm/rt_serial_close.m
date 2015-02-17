function rt_serial_close(PORT, captureFileID)
%SERIAL_CLOSE Summary of this function goes here
%   Detailed explanation goes here
try %try to close any we can in case they are faulty.
  invoke(PORT,'stopcapture');
  invoke(PORT,'close'); 
  
  
    % empty the capture file field
    filename = PORT.CaptureFile;
    PORT.CaptureFile = '';
    delete(PORT);
    % close it
    fclose(captureFileID);

    % delete the file if it exists
    if exist(filename, 'file')
        
    % delete it
    warning('off','MATLAB:DELETE:Permission');
    delete(filename)
    end
  
  disp('COM PORT CLOSED');
catch
end; %try

end

