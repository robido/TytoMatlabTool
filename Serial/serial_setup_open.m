function [serConn,serTimer] = serial_setup_open( serPort, Baud )

serConn = serial(serPort, 'TimeOut', 1, 'BaudRate', Baud);
    
    serConn.BytesAvailableFcnCount = 1;
    serConn.BytesAvailableFcnMode = 'byte';
    
    %Timer needed to ensure minimum delay between commands (otherwise board
    %cannot keep up due to filled buffers or something)
    serTimer = timer('TimerFcn',{@serial_ISR_delay,serConn},'StartDelay',0.0,'ExecutionMode','singleShot');
    
    serConn.BytesAvailableFcn={@serial_ISR_RX,serConn,serTimer};
    %serConn.OutputEmptyFcn={@serial_ISR_TX,serConn};
    
    try
    fopen(serConn);
    disp('COM PORT OPENED');
    catch e
        errordlg(e.message);
        serConn = 0;
        serTimer = 0;
    end
end

