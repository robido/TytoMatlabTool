function DISP_string = protocol_get_M_display( STATE, List_of_commands )

DISP_string = [];

size_commands = size(List_of_commands,2);
for i=1:size_commands
    ID = List_of_commands(i);
    switch ID
        case 101
            cycleTime = protocol_get_cycleTime(STATE);
            i2c_error = protocol_get_i2c_errors(STATE);
            DISP_string = [DISP_string,'cycleTime (us):',32,num2str(cycleTime),10,13];
            DISP_string = [DISP_string,'cycleTime (Hz):',32,num2str(round(1000000/cycleTime)),10,13];
            if(i2c_error>0)
                DISP_string = [DISP_string,'*** I2C errors ***:',32,num2str(i2c_error),10,13];
            end
        case 102
            [accSmooth gyroData magADC] = protocol_get_IMU(STATE);
            DISP_string = [DISP_string,'IMU (ROLL PITCH YAW):',10,13];
            DISP_string = [DISP_string,9,'accSmooth:',9,num2str(accSmooth),10,13];
            DISP_string = [DISP_string,9,'gyroData:',9,num2str(gyroData),10,13];
            DISP_string = [DISP_string,9,'magADC:',9,num2str(magADC),10,13];
            %DISP_string = [DISP_string,9,'gyroADC:',9,num2str(gyroADC),10,13];
            %DISP_string = [DISP_string,9,'accADC:',9,num2str(accADC),10,13];
        case 254
            debug = protocol_get_debug(STATE);
            DISP_string = [DISP_string,'debug:',32,num2str(debug),10,13];

    end
end

