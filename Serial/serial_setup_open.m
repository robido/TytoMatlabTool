function s = serial_setup_open( serPort, Baud )

    s = serial(serPort,'BaudRate',Baud);
    fopen(s);
    pause(2);

end

