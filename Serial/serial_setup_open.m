function [hrealterm, captureFileID] = serial_setup_open( serPort, Baud )

    
    hrealterm=actxserver('realterm.realtermintf'); % start Realterm as a server
    hrealterm.baud=Baud;
    hrealterm.Port=serPort;
    hrealterm.windowstate=1; %minimized
    try
        hrealterm.PortOpen=1; %open the comm port
        pause(0.5); %Allow initialisation time

        if(hrealterm.PortOpen~=0)
            disp(strcat('SERIAL PORT OPENED: COM',serPort));
        else
            disp('COULD NOT OPEN SERIAL PORT');
        end%check that it opened OK

        hrealterm.CaptureFile=strcat(pwd,'\Serial\serial_data.dat');
        invoke(hrealterm,'startcapture'); %start capture
        captureFileID = fopen(hrealterm.CaptureFile);

        %Ensure buffer is empty
        next_byte = serial_get_byte(captureFileID);
        while(~isempty(next_byte))
            next_byte = serial_get_byte(captureFileID);
        end
    catch e
        msgbox(e.message,'ERROR','error');
        hrealterm = -1;
    end
    
   

end

