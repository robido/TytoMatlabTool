function [STATE Message YAW] = TailScript(STATE)

%PARAMETERS
%YAW starts at 1190
%YAW should be limited to 1400
YAW_MAX = 1400;
YAW_MIN = 1020;
CALIB_TIME = 10; %How long to calibrate
TEST_STEPS = 50; %How many datapoints to get. Will do each back and forth
SETTLE_TIME = 1.5; %How long to settle after change of power
STEP_DURATION = 3; %How long to record data for the step

%For display text
TOTAL_TIME = CALIB_TIME + (2*TEST_STEPS)*(SETTLE_TIME+STEP_DURATION); 
CURRENT_TIME = 0;

persistent STEP counter DATA TailMessage
if isempty(STEP) || STATE.RESET_TEST
    STEP = 1;
    counter = 0;
    STATE.RESET_TEST = 0;
    TailMessage = '';
end

YAW = YAW_MIN; %Default response

%Extract parameters
ALL_PARAMS = 0;
try
    VBAT = STATE.R.MSP_TEST_JIG_DATA.Vbat;
    TORQUE = STATE.R.MSP_TEST_JIG_DATA.Torque_sensor;
    CURRENT = STATE.R.MSP_TEST_JIG_DATA.Current;
    ALL_PARAMS = 1;
catch
    TailMessage = 'Waiting for hardware to respond...';
end

if(ALL_PARAMS && STEP>0)
    %Check parameters range
    if(VBAT<6.4 || VBAT>8.4)
        TailMessage = 'TEST FAILED: Input voltage out of range [6.4 - 8.4]v.';
        STEP = -1;
    end
    
    switch STEP
        case 1 %Calibrate sensors
            YAW = YAW_MIN;
            if(counter == 0)
                DATA.Calib.Torque = [];
                DATA.Calib.Current = [];
                counter = now;
            else            
                duration = (now-counter)*24*3600;
                CURRENT_TIME = duration;
                DATA.Calib.Torque = [DATA.Calib.Torque TORQUE];
                DATA.Calib.Current = [DATA.Calib.Current CURRENT];
                
                if(duration>CALIB_TIME)
                    DATA.Calib.Torque = mean(DATA.Calib.Torque);
                    DATA.Calib.Current = mean(DATA.Calib.Current);
                    STEP = STEP + 1;
                    counter = 0;
                    CURRENT_TIME = CALIB_TIME;
                end
            end
            TailMessage = 'Calibrating sensors...';
        case 2
            %Setup the experiment with varying power level starting at the
            %lowest to stop, and back.
            STEP_SIZE = (YAW_MAX-YAW_MIN)/TEST_STEPS;
            DATA.Result.YAW = round((YAW_MIN+STEP_SIZE):STEP_SIZE:YAW_MAX);
            A = fliplr(DATA.Result.YAW);
            A(1)=[];         
            DATA.Result.YAW = [DATA.Result.YAW A YAW_MIN]; %Reverse the experiment too with one being null speed
            DATA.Result.AvgTorque = zeros(size(DATA.Result.YAW));
            DATA.Result.AvgCurrent = zeros(size(DATA.Result.YAW));
            DATA.Result.AvgVBAT = zeros(size(DATA.Result.YAW));
            DATA.Index = 1;
            STEP = STEP + 1;
            counter = 0;
        case 3
            %SETTLE TIME
            YAW = DATA.Result.YAW(DATA.Index);
            TailMessage = 'Settling...';
            
            %Calculate time
            CURRENT_TIME = CALIB_TIME + ...
                (SETTLE_TIME+STEP_DURATION) * (DATA.Index-1);
            
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
            
        case 4
            %RECORDING RESULTS
            YAW = DATA.Result.YAW(DATA.Index);
            TailMessage = 'Recording data...';
            
            %Calculate time
            CURRENT_TIME = CALIB_TIME + ...
                SETTLE_TIME + ...
                (SETTLE_TIME+STEP_DURATION) * (DATA.Index-1);
            
            if(counter == 0)
                counter = now;
                DATA.Result.Torque = [];
                DATA.Result.Current = [];
                DATA.Result.VBAT = [];
            else
                duration = (now-counter)*24*3600;
                CURRENT_TIME = CURRENT_TIME + duration;
                DATA.Result.Torque = [DATA.Result.Torque TORQUE];
                DATA.Result.Current = [DATA.Result.Current CURRENT];
                DATA.Result.VBAT = [DATA.Result.VBAT VBAT];
                
                if(duration>STEP_DURATION)
                    DATA.Result.AvgTorque(DATA.Index) = mean(DATA.Result.Torque)-DATA.Calib.Torque;
                    DATA.Result.AvgCurrent(DATA.Index) = mean(DATA.Result.Current)-DATA.Calib.Current;
                    DATA.Result.AvgVBAT(DATA.Index)= mean(DATA.Result.VBAT);
                    DATA.Index = DATA.Index + 1;
                    counter = 0;
                    if(DATA.Index > numel(DATA.Result.YAW))
                        STEP = -1;
                        TailMessage = 'Finished! Data and graphics saved.';
                        save_tail_data(DATA,YAW_MIN,YAW_MAX);
                        YAW = YAW_MIN;
                    else
                        STEP = STEP - 1;
                    end
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

Message = strcat(num2str(Percentage),'%',32,'(',minutes,num2str(Time_left),'s remaining)',10,13,TailMessage);

end

