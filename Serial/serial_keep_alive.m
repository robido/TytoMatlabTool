function serial_keep_alive(~,~,PORT)
global SERIAL_SENT

if(SERIAL_SENT<5)
    protocol_send_command(PORT,101); %Trigger a new message to restart transmission
    disp('TRIGGER');
    SERIAL_SENT = 0;
end

