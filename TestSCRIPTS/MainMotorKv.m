function [STATE Message THROTTLE] = MainMotorKv(STATE)
%MAINMOTORSCRIPT Returns the motor estimated Kv

%PARAMETERS
CALIB_TIME = 10; %How long to calibrate
SETTLE_TIME = 9; %How long to settle after change of power
STEP_DURATION = 5; %How long to record data for the step
THROTTLE_MIN = 1020;
FULL_THROTTLE = 2000;

%For display text
TOTAL_TIME = CALIB_TIME + SETTLE_TIME + STEP_DURATION; 
CURRENT_TIME = 0;

persistent STEP counter DATA KvMessage WINDING_RESISTANCE
if isempty(STEP) || STATE.RESET_TEST
    STEP = 1;
    counter = 0;
    STATE.RESET_TEST = 0;
    KvMessage = '';
    answer = inputdlg('Enter winding resistance (Ohms)');
    WINDING_RESISTANCE = str2num(answer{1});
end

THROTTLE = THROTTLE_MIN; %Default response

%Extract parameters
ALL_PARAMS = 0;
try
    VBAT = STATE.R.MSP_TEST_JIG_DATA.Vbat;
    CURRENT = STATE.R.MSP_TEST_JIG_DATA.Current;
    RPM = STATE.M.MSP_TEST_JIG_DATA.MainMotor_rpm;
    ALL_PARAMS = 1;
catch
    KvMessage = 'Waiting for hardware to respond...';
end

if(ALL_PARAMS && STEP>0)   
    switch STEP
        case 1 %Calibrate sensors
            THROTTLE = THROTTLE_MIN;
            if(counter == 0)
                DATA.Calib.Current = [];
                counter = now;
            else            
                duration = (now-counter)*24*3600;
                CURRENT_TIME = duration;
                DATA.Calib.Current = [DATA.Calib.Current CURRENT];
                
                if(duration>CALIB_TIME)
                    DATA.Calib.Current = mean(DATA.Calib.Current);
                    STEP = STEP + 1;
                    counter = 0;
                    CURRENT_TIME = CALIB_TIME;
                end
            end
            KvMessage = 'Calibrating sensors...';
        case 2
            %SETTLE TIME
            THROTTLE = FULL_THROTTLE;
            KvMessage = 'Settling...';
            
            %Calculate time
            CURRENT_TIME = CALIB_TIME;
            
            if(counter == 0)
                counter = now;
            else
                duration = (now-counter)*24*3600;
                CURRENT_TIME = CURRENT_TIME + duration;
                if(duration > SETTLE_TIME)
                    STEP = STEP + 1;
                    counter = 0;
                end
            end
        case 3
            %RECORDING RESULTS
            THROTTLE = FULL_THROTTLE;
            KvMessage = 'Recording data...';
            
            %Calculate time
            CURRENT_TIME = CALIB_TIME + SETTLE_TIME;
            
            if(counter == 0)
                counter = now;
                DATA.Result.RPM = [];
                DATA.Result.Current = [];
                DATA.Result.VBAT = [];
            else
                duration = (now-counter)*24*3600;
                CURRENT_TIME = CURRENT_TIME + duration;
                DATA.Result.RPM = [DATA.Result.RPM RPM];
                DATA.Result.Current = [DATA.Result.Current CURRENT];
                DATA.Result.VBAT = [DATA.Result.VBAT VBAT];
                
                if(duration>STEP_DURATION)
                    DATA.Result.AvgRPM = mean(DATA.Result.RPM);
                    DATA.Result.AvgCurrent = mean(DATA.Result.Current)-DATA.Calib.Current;
                    DATA.Result.AvgVBAT = mean(DATA.Result.VBAT);
                    counter = 0;
                    STEP = -1;
                    KvMessage = 'Finished!';
                    
                    %Calculate Kv
                    KV = round(DATA.Result.AvgRPM/DATA.Result.AvgVBAT);
                    Rm = WINDING_RESISTANCE;
                    RealKv = DATA.Result.AvgRPM/(DATA.Result.AvgVBAT-(0.001*DATA.Result.AvgCurrent*Rm)); %Kv = RPM / (Volts ? Amps × Rm)
                    KvMessage = ['Measured Kv is:', 32, num2str(KV),'. Current was:',...
                        32,num2str(round(DATA.Result.AvgCurrent)),'mA.',...
                        32,'Voltage:',32,num2str(VBAT),'V. If Rm=',...
                        num2str(Rm),'Ohm, then Kv becomes',32,num2str(round(RealKv)),'.'];
                    disp(KvMessage);
                    
                    THROTTLE = THROTTLE_MIN;
                end
            end
    end
end

Percentage = round(100*CURRENT_TIME/TOTAL_TIME);
Time_left = round(max(0,TOTAL_TIME-CURRENT_TIME));
minutes = floor(Time_left/60);
Time_left = Time_left - 60*minutes;

if(minutes>0)
    minutes = strcat(num2str(minutes),'m');
else
    minutes = '';
end

Message = strcat(num2str(Percentage),'%',32,'(',minutes,num2str(Time_left),'s remaining)',10,13,KvMessage);

end
