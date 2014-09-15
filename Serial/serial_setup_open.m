function [serConn,serTimer] = serial_setup_open( serPort, Baud )
global SERIAL_SENT
SERIAL_SENT = 0;
serConn = serial(serPort, 'TimeOut', 1, 'BaudRate', Baud);
    
    serConn.BytesAvailableFcnCount = 1;
    serConn.BytesAvailableFcnMode = 'byte';
    
    %Timer to start communication and keep it alive if a packet is ever
    %droppped
    serTimer = timer('TimerFcn',{@serial_keep_alive,serConn},'StartDelay',2.0,'Period',0.5,'ExecutionMode','fixedSpacing');
    serConn.BytesAvailableFcn={@serial_ISR_RX,serConn};
    
    try
    fopen(serConn);
    disp('COM PORT OPENED');
    pause(2); %Allow C
    protocol_send_command(serConn,101); %Trigger the first message. %% SHOULD BE RUNNING IN INTERRUPT MODE
    catch e
        errordlg(e.message);
        serConn = 0;
        serTimer = 0;
    end
end

