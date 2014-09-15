function [ output_args ] = serial_ISR_RX(hObject, event, serConn, delay_tmr)
%SERIAL_ISR_RX % Called whenever data is received in the serial port
global LAST_ACK

while(serConn.BytesAvailable()>0)
    byte = fread(serConn,1,'uchar');
    LAST_ACK = protocol_process(byte);
    drawnow;
    if(LAST_ACK), serial_ISR_delay('','',serConn); end
    %if(LAST_ACK), start(delay_tmr); end
end

end
