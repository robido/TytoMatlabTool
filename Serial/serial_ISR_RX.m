function [ output_args ] = serial_ISR_RX(hObject, event, serConn)
%SERIAL_ISR_RX % Called whenever data is received in the serial port
global LAST_ACK SERIAL_SENT

while(serConn.BytesAvailable()>0)
        try
            byte = fread(serConn,1,'uchar');
            LAST_ACK = protocol_process(byte);
            if(LAST_ACK)
               protocol_send_command(serConn,LAST_ACK);
               drawnow; pause(0.001);%Needed to avoid timing problems related to MATLAB and PC serial port
               SERIAL_SENT = SERIAL_SENT + 1;
            end
        catch
        end       
end

end
