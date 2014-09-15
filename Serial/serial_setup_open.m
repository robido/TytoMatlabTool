function [serConn] = serial_setup_open( serPort, Baud )
global SERIAL_SENT
SERIAL_SENT = 0;
serConn = serial(serPort, 'TimeOut', 1, 'BaudRate', Baud);

try
    fopen(serConn);
    disp('COM PORT OPENED');
    pause(0.5); %Allow initialisation time
    
    %Ensure buffer is empty
    while(serConn.BytesAvailable()>0)
        fread(serConn,1,'uchar');
    end
catch e
        errordlg(e.message);
        serConn = 0;
end
end

