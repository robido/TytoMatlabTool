function [STATE Message PITCH THROTTLE] = MainMotorScriptV2(STATE)
%MAINMOTORSCRIPT This version tries all combinations of pitch and throttle.

%PARAMETERS
MOTOR_START_POWER = 1150; %Initial throttle value
MAX_RPM = 5500; %Hard limit to protect system
MAX_THROTTLE = 2000;
THROTTLE_RATE = 90; %Time in seconds to go from min to max throttle during test
SPOOLUP_TIME = 5; %Time to wait at initial throttle before recording test

%Temperature parameters
COOLING_THROTTLE = 1125; %Turning the motor at low power cools the motor faster due to convection
MAX_INIT_TEMP_DELTA = 20; %Motor must be within this temperature relative to ambient before test
OVERHEAT = 60; %Not too high as the motor has tendency to increase more after stopped

%Trust
OVERCURRENT = 6000; %6A max (experimentally, the motor reaches 60C at 2.5A cont.)
MAX_POWER = 30; %Watts

%Durations
CALIB_TIME = 10; %How long to calibrate

%Default response
DEFAULT_THROTTLE = 1020;
DEFAULT_PITCH = 1500;
MIN_PITCH = 1020; %Reversed, ie lower pitch = more trust
MAX_PITCH = 2000;
PITCH_STEPS = 20;

persistent STEP counter DATA MainMessage index last_time FILE CURRENT_TEST PITCH_VALUES;
if isempty(STEP) || STATE.RESET_TEST
    STEP = 1;
    counter = 0;
    last_time = now;
    STATE.RESET_TEST = 0;
    MainMessage = '';
    index = 1;
    CURRENT_TEST = 0;
    PITCH_VALUES = round(MAX_PITCH:(MIN_PITCH-MAX_PITCH)/(PITCH_STEPS-1):MIN_PITCH);
    DATA.MotorColdCount = 0;
    
    DATA.ResultArray.THROTTLE = [];
    DATA.ResultArray.PITCH = [];
    DATA.ResultArray.RPM = [];
    DATA.ResultArray.Trust = [];
    DATA.ResultArray.Torque = [];
    DATA.ResultArray.Vbat = [];
    DATA.ResultArray.Current = [];
    DATA.ResultArray.AmbientTemp = [];
    DATA.ResultArray.MotorTemp = [];
    
    %Get file to save
    filename = 0;
    pathname = 0;
    [filename, pathname] = uiputfile('*.csv','Pick a location for saving the data, or select an existing one to append data to it.');
    if(isequal(filename,0) || isequal(pathname,0))
        MainMessage = 'Test cancel, no file selected.';
        STEP = -1;
    else
        [pathstr,name,ext] = fileparts([pathname filename]);
        file = [pathstr '\' name ext];
        FILE.file = file;
        FILE.pathstr = pathstr;
        FILE.name = name;
        FILE.ext = ext;
        
        %Create header if file doesn't exist
        if exist(file, 'file') ~= 2
            save_trust_dataV2(FILE,'',DATA.ResultArray);
            MainMessage = 'File was created. Please restart test and select existing file.';
            STEP = -1;
        else
            %Get the list of uncompleted tests
            PITCH_VALUES = get_trust_testsV2(file,PITCH_VALUES);
            if(isempty(PITCH_VALUES))
                MainMessage = 'All tests done in the selected file.';
                STEP = -1;
            end
        end
    end
end

THROTTLE = DEFAULT_THROTTLE;
PITCH = DEFAULT_PITCH;

%Extract parameters
ALL_PARAMS = 0;
if(STEP ~= -1)
    try
        VBAT = STATE.R.MSP_TEST_JIG_DATA.Vbat;
        TORQUE = STATE.R.MSP_TEST_JIG_DATA.Torque_sensor;
        CURRENT = STATE.R.MSP_TEST_JIG_DATA.Current;
        RPM = STATE.M.MSP_TEST_JIG_DATA.MainMotor_rpm;
        TRUST = STATE.R.MSP_TEST_JIG_DATA.Trust_scale;
        T_MOTOR = STATE.R.MSP_TEST_JIG_DATA.MainMotor_temp;
        T_AMBIENT = STATE.R.MSP_TEST_JIG_DATA.Room_temp;
        ALL_PARAMS = 1;
    catch
        MainMessage = 'Waiting for hardware to respond...';
    end
end

if(ALL_PARAMS && STEP>0)
    %Check parameters range
    if(VBAT<13.8 || VBAT>15.8)
        MainMessage = strcat('TEST FAILED: Input voltage out of range. Set to 14.8v.',32,num2str(VBAT),'V.');
        STEP = -1;
    end
    
    if(STEP == 1 && (TRUST<-3 || TRUST>3))
        MainMessage = 'TEST FAILED: Please calibrate trust sensor to be 0g (using little screw on op-amp circuit).';
        STEP = -1;
    end
    
    if(STEP == 1 && (T_AMBIENT<15 || T_MOTOR<15))
        MainMessage = 'TEST FAILED: Temp sensor under 15C, does not seem normal for lab conditions.';
        STEP = -1;
    end
    
    %Apply calibration
    if(STEP>1)
        TORQUE = TORQUE - DATA.Calib.Torque;
        CURRENT = CURRENT - DATA.Calib.Current;
        TRUST = TRUST - DATA.Calib.Trust;
    end
    
    switch STEP
        case 1 %Calibrate sensors
            if(counter == 0)
                DATA.Calib.Torque = [];
                DATA.Calib.Current = [];
                DATA.Calib.Trust = [];
                counter = now;
                duration = 0;
            else
                duration = (now-counter)*24*3600;
                DATA.Calib.Torque = [DATA.Calib.Torque TORQUE];
                DATA.Calib.Current = [DATA.Calib.Current CURRENT];
                DATA.Calib.Trust = [DATA.Calib.Trust TRUST];
                
                if(duration>CALIB_TIME)
                    DATA.Calib.Torque = mean(DATA.Calib.Torque);
                    DATA.Calib.Current = mean(DATA.Calib.Current);
                    DATA.Calib.Trust = mean(DATA.Calib.Trust);
                    STEP = STEP + 1;
                    counter = 0;
                end
            end
            MainMessage = strcat('Calibrating sensors',32,num2str(round(100*duration/CALIB_TIME)),'%...');
        case 2 %Ensure motor is cold to start test
            if(T_MOTOR-T_AMBIENT < MAX_INIT_TEMP_DELTA && T_MOTOR>0)
                DATA.MotorColdCount = DATA.MotorColdCount + 1;
            else
                DATA.MotorColdCount = 0;
            end
            if(DATA.MotorColdCount > 10)
                %Motor is cold, go to next step
                STEP = STEP+1;
                last_time = now;
                DATA.start_time = last_time;
                CURRENT_TEST = CURRENT_TEST + 1;
            end
            PITCH = DEFAULT_PITCH;
            THROTTLE = COOLING_THROTTLE;
            MainMessage = 'Waiting for motor to cool down...';
        case 3 %Spoolup phase
            current_time = now;
            time_since_start = (current_time - DATA.start_time)*24*3600;
            PITCH = PITCH_VALUES(index);
            THROTTLE = MOTOR_START_POWER;
            if(time_since_start>SPOOLUP_TIME)
                STEP = STEP+1;
                last_time = now;
                DATA.start_time = last_time;
            end
            MainMessage = 'Spooling up...';
        case 4 %Run the test
            TEST_FINISHED = '';
            
            %Timing
            current_time = now;
            %dt = (current_time-last_time)*24*3600;
            last_time = current_time;
            time_since_start = (current_time - DATA.start_time)*24*3600;
            
            %Check rpm sensor
            if(time_since_start>4 && RPM<100)
                TEST_FINISHED = 'RPM SENSOR PROBLEM';
                MainMessage = strcat('TEST FAILED: RPM sensor says motor is stopped.');
                STEP = -1;
            end
            
            %Check current sensor during spool up
            if(time_since_start>3 && time_since_start<5 && CURRENT<30)
                TEST_FINISHED = 'CURRENT SENSOR PROBLEM';
                MainMessage = strcat('TEST FAILED: Current sensor seems incorrect.');
                STEP = -1;
            end
            
            if(CURRENT>OVERCURRENT)
                TEST_FINISHED = ['OVERCURRENT:' 32 num2str(round(CURRENT)) 'mA.'];
            end
            
            power = 0.001*CURRENT*VBAT;
            if(power > MAX_POWER)
                TEST_FINISHED = ['POWER >' 32 num2str(round(power)) 'W.'];
            end
            
            %Check temp sensor still attached to motor
            if(time_since_start>50 && CURRENT>3000)
                if(T_MOTOR-T_AMBIENT)<3
                    TEST_FINISHED = 'TEMP SENSOR DETACHED?';
                    MainMessage = strcat('TEST FAILED: Temp sensor seems to have detached from motor.');
                    STEP = -1;
                end
            end
            
            if(T_MOTOR>OVERHEAT)
                TEST_FINISHED = strcat('OVERHEAT',32,num2str(T_MOTOR),'C');
                PITCH = DEFAULT_PITCH;
                THROTTLE = COOLING_THROTTLE;
                disp('Motor overheat');
            end
            
            if(TRUST<-5)
                TEST_FINISHED = 'TRUST NEGATIVE';
            end
            
            if(RPM>MAX_RPM)
                TEST_FINISHED = 'MAX RPM';
            end
            
            if(isempty(TEST_FINISHED))
                %Target
                throttle_ratio = time_since_start/THROTTLE_RATE;
                PITCH = PITCH_VALUES(index);
                THROTTLE = round((1.0-throttle_ratio)*MOTOR_START_POWER+throttle_ratio*MAX_THROTTLE);
                MainMessage = ['PITCH:',32,num2str(PITCH),10,13,'THROTTLE:',32,num2str(THROTTLE)];
                
                %Save data
                DATA.ResultArray.THROTTLE = [DATA.ResultArray.THROTTLE THROTTLE];
                DATA.ResultArray.PITCH = [DATA.ResultArray.PITCH PITCH];
                DATA.ResultArray.RPM = [DATA.ResultArray.RPM RPM];
                DATA.ResultArray.Trust = [DATA.ResultArray.Trust TRUST];
                DATA.ResultArray.Torque = [DATA.ResultArray.Torque TORQUE];
                DATA.ResultArray.Vbat = [DATA.ResultArray.Vbat VBAT];
                DATA.ResultArray.Current = [DATA.ResultArray.Current CURRENT];
                DATA.ResultArray.AmbientTemp = [DATA.ResultArray.AmbientTemp T_AMBIENT];
                DATA.ResultArray.MotorTemp = [DATA.ResultArray.MotorTemp T_MOTOR];
            end
            
            MainMessage = [MainMessage 10 13 'Currently ', num2str(RPM) ,'rpm and',32,num2str(TRUST),'g of trust.'];
            
            if(THROTTLE >= MAX_THROTTLE)
                TEST_FINISHED = 'MAX THROTTLE REACHED';
            end
            
            if(STATE.skipcurrent)
                answer = inputdlg('Enter reason for skipping');
                TEST_FINISHED = answer{1};
                TEST_FINISHED = ['SKIPPED:',32,TEST_FINISHED];
                STATE.skipcurrent = 0;
            end
            
            %Save data and decide what to do next
            if(~isempty(TEST_FINISHED))
                save_trust_dataV2(FILE,TEST_FINISHED,DATA.ResultArray);
                parameters_file = [FILE.pathstr '\' FILE.name];
                save(parameters_file); %Save workspace variables
                disp(TEST_FINISHED);
                index = index + 1;
                if(index>numel(PITCH_VALUES))
                    STEP = -1;
                    MainMessage = 'All tests done';
                else
                    STEP = 2;
                    DATA.MotorColdCount = 0;
                    
                    DATA.ResultArray.THROTTLE = [];
                    DATA.ResultArray.PITCH = [];
                    DATA.ResultArray.RPM = [];
                    DATA.ResultArray.Trust = [];
                    DATA.ResultArray.Torque = [];
                    DATA.ResultArray.Vbat = [];
                    DATA.ResultArray.Current = [];
                    DATA.ResultArray.AmbientTemp = [];
                    DATA.ResultArray.MotorTemp = []; 
                end
            end
    end
end

total_tests = numel(PITCH_VALUES);
Message = strcat('Test',32,num2str(min(index,total_tests)),' of',32,num2str(total_tests),'.',10,13,MainMessage);

end
