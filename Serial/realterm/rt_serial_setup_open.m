function [hrealterm, captureFileID] = rt_serial_setup_open( serPort, Baud )

    
    hrealterm=actxserver('realterm.realtermintf'); % start Realterm as a server
    hrealterm.baud=Baud;
    hrealterm.Port=serPort;
    hrealterm.windowstate=1; %minimized
    hrealterm.DTR=0;
    hrealterm.RTS=0;
    hrealterm.MonitorOn=1;
    
    try
        hrealterm.PortOpen=1; %open the comm port
        pause(2); %Allow initialisation time (too short and the serial port in windows will not respond...)

        if(hrealterm.PortOpen~=0)
            disp(strcat('SERIAL PORT OPENED: COM',serPort));
        else
            disp('COULD NOT OPEN SERIAL PORT');
        end%check that it opened OK

        hrealterm.CaptureFile=strcat(pwd,'\Serial\serial_data.dat');
        invoke(hrealterm,'startcapture'); %start capture
        captureFileID = fopen(hrealterm.CaptureFile);

        %Ensure buffer is empty
        pause(1);
        next_byte = rt_serial_get_byte(captureFileID);
        while(~isempty(next_byte))
            pause(0.2);
            next_byte = rt_serial_get_byte(captureFileID);
        end
        %pause(4); %Allow initialisation time (too short and the serial port in windows will not respond...)
    catch e
        msgbox([e.message 10 13 10 13 'SOLUTION: most likely the port number is not written correctly. Try to write "3" instead of "COM3".'],'ERROR','error');
        hrealterm = -1;
    end   

end

