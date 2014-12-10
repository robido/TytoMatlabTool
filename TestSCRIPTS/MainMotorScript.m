function [STATE Message PITCH THROTTLE] = MainMotorScript(STATE)
%MAINMOTORSCRIPT Summary of this function goes here
%   Detailed explanation goes here

%PARAMETERS
MOTOR_START_POWER = 1150; %Initial throttle value
MAX_RPM = 6000; %Hard limit to protect system

%Temperature parameters
SETTLE_TEMPERATURE = 0; %Activate if the test should settle in temp as well
COOLING_THROTTLE = 1115; %Turning the motor at low power cools the motor faster due to convection
MAX_INIT_TEMP_DELTA = 20; %Motor must be within this temperature relative to ambient before test
TEMP_TOLERANCE = 1; %Steadystate difference (to consider test valid)
OVERHEAT = 60; %Not too high as the motor has tendency to increase more after stopped

%RPM
RPM_TOLERANCE = 75; %Steadystate difference (to consider test valid)
SPOOL_UP_RATE = 20; %Throttle signal (ms) / second

%Trust
TRUST_TOLERANCE = 7; %Steadystate difference (to consider test valid)
PITCH_RATE = 20; %Pitch signal (ms) / second
OVERCURRENT = 6000; %6A max (experimentally, the motor reaches 60C at 2.5A cont.)

%Controller
RPM_I_TERM = 0.03;
PITCH_I_TERM = 0.5;

%Durations
CALIB_TIME = 10; %How long to calibrate
STEP_DURATION = 30; %Test duration (must be steady state during this whole duration)
if(SETTLE_TEMPERATURE)
    TIME_LIMIT = 15*60; %Time after which the test gives up (cannot reach targets)
else
    TIME_LIMIT = 4*60; %Time after which the test gives up (cannot reach targets)
end
    
%Default response
DEFAULT_THROTTLE = 1020;
DEFAULT_PITCH = 1500;

persistent STEP counter DATA MainMessage index controller last_time FILE CURRENT_TEST;
if isempty(STEP) || STATE.RESET_TEST
    STEP = 1;
    counter = 0;
    last_time = now;
    STATE.RESET_TEST = 0;
    MainMessage = '';
    index = 1;
    controller.throttle = DEFAULT_THROTTLE;
    controller.pitch = DEFAULT_PITCH; 
    CURRENT_TEST = 0;
    DATA.MotorColdCount = 0;
    
    DATA.ResultArray.Time = [];
    DATA.ResultArray.RPM = [];
    DATA.ResultArray.Trust = [];
    DATA.ResultArray.Torque = [];
    DATA.ResultArray.Vbat = [];
    DATA.ResultArray.Current = [];
    DATA.ResultArray.AmbientTemp = [];
    DATA.ResultArray.MotorTemp = [];
    DATA.ResultArray.THROTTLE = [];
    DATA.ResultArray.PITCH = [];
      
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
            save_trust_data(FILE,0,'',0,0,DATA.ResultArray);
            MainMessage = 'File was created. Please open it and add test points (fill in targetRPM and targetTrust fields for as many rows as required, and leave rest blank), then run the test again by selecting this file.';
            STEP = -1;
        else
            %Get the list of uncompleted tests
            FILE.tests_list = get_trust_tests(file);
            if(isempty(FILE.tests_list))
                MainMessage = 'No tests were defined in the selected file.';
                STEP = -1;
            end
        end    
    end
end

THROTTLE = DEFAULT_THROTTLE; 
PITCH = DEFAULT_PITCH;

%Extract parameters
ALL_PARAMS = 0;
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

if(ALL_PARAMS && STEP>0)
    %Check parameters range
    if(VBAT<6.4 || VBAT>8.4)
        MainMessage = strcat('TEST FAILED: Input voltage out of range [6.4 - 8.4]v.',32,num2str(VBAT),'V.');
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
                controller.throttle = MOTOR_START_POWER;
                controller.pitch = DEFAULT_PITCH; 
                CURRENT_TEST = CURRENT_TEST + 1;
            end
            THROTTLE = COOLING_THROTTLE;
            MainMessage = 'Waiting for motor to cool down...';
        case 3 %Run the test
            TEST_FINISHED = '';
            WITHIN_TOLERANCE = 0;
            
            %Targets 
            targetRPM = FILE.tests_list(index,2);
            targetTrust = FILE.tests_list(index,3);
            if(targetRPM>MAX_RPM)
                TEST_FINISHED = 'TARGET RPM TOO HIGH';
            end
            DATA.targetRPM = targetRPM;
            DATA.targetTrust = targetTrust;
            TOTAL_tests = size(FILE.tests_list,1);
            MainMessage = strcat('Test',32,num2str(CURRENT_TEST),' of',32,num2str(TOTAL_tests),'.',10,13);
            
            %Timing
            current_time = now;
            dt = (current_time-last_time)*24*3600;
            last_time = current_time;
            time_since_start = (current_time - DATA.start_time)*24*3600;
            
            %Check rpm sensor
            if(time_since_start>5 && RPM<200)
                TEST_FINISHED = 'RPM SENSOR PROBLEM';
                MainMessage = strcat('TEST FAILED: RPM sensor says motor is stopped.');
                STEP = -1;
            end
            
            %Check current sensor during spool up
            if(time_since_start>2 && time_since_start<5 && CURRENT<200)
                TEST_FINISHED = 'CURRENT SENSOR PROBLEM';
                MainMessage = strcat('TEST FAILED: Current sensor seems incorrect.');
                STEP = -1;
            end
            if(CURRENT>OVERCURRENT)
                TEST_FINISHED = ['OVERCURRENT:' 32 num2str(round(CURRENT)) 'mA.'];
            end
            
            %Check temp sensor still attached to motor
            if(time_since_start>50 && CURRENT>3000)
                if(T_MOTOR-T_AMBIENT)<3
                    TEST_FINISHED = 'TEMP SENSOR DETACHED?';
                    MainMessage = strcat('TEST FAILED: Temp sensor seems to have detached from motor.');
                    STEP = -1;
                end
            end
            
            if(isempty(TEST_FINISHED))
                %Temperature check
                if(T_MOTOR>OVERHEAT)
                    TEST_FINISHED = strcat('OVERHEAT',32,num2str(T_MOTOR),'C');
                    controller.pitch = DEFAULT_PITCH;
                    controller.throttle = COOLING_THROTTLE;
                    disp('Motor overheat')
                else
                    if(RPM>(targetRPM-RPM_TOLERANCE) && RPM<(targetRPM+RPM_TOLERANCE))
                        WITHIN_TOLERANCE = WITHIN_TOLERANCE+1;
                    else
                        MainMessage = [MainMessage 'RPM out of target range' 10 13];
                    end

                    if(TRUST>(targetTrust-TRUST_TOLERANCE) && TRUST<(targetTrust+TRUST_TOLERANCE))
                        WITHIN_TOLERANCE = WITHIN_TOLERANCE+1;
                    else
                        MainMessage = [MainMessage 'TRUST out of target range' 10 13];
                    end

                    %First target ballpark values to be in the correct range            
                    if(RPM<(targetRPM-RPM_TOLERANCE))
                        MainMessage = [MainMessage 'Spooling up to ', num2str(targetRPM) ,'rpm.'];
                        controller.throttle = controller.throttle + dt*SPOOL_UP_RATE;
                    else
                        if(RPM>(targetRPM+RPM_TOLERANCE*2))
                            MainMessage = [MainMessage 'Slowing down to ', num2str(targetRPM) ,'rpm.'];
                            controller.throttle = controller.throttle - dt*SPOOL_UP_RATE;
                        else
                            if(TRUST<(targetTrust-TRUST_TOLERANCE*2))
                                MainMessage = [MainMessage 'Increasing pitch towards ', num2str(targetTrust) ,'g trust.'];
                                controller.pitch = controller.pitch - dt*PITCH_RATE;
                            else
                                if(TRUST>(targetTrust+TRUST_TOLERANCE*2))
                                    MainMessage = [MainMessage 'Decreasing pitch towards ', num2str(targetTrust) ,'g trust.'];
                                    controller.pitch = controller.pitch + dt*PITCH_RATE;
                                else
                                    %Adjust both simultaneously
                                    MainMessage = [MainMessage 'Targeting ', num2str(targetRPM) ,'rpm and',32,num2str(targetTrust),'g trust.'];
                                    rpm_error = RPM-targetRPM;
                                    trust_error = TRUST-targetTrust;
                                    controller.throttle = controller.throttle - rpm_error*dt*RPM_I_TERM;
                                    controller.pitch = controller.pitch + trust_error*dt*PITCH_I_TERM;
                                end
                            end
                        end
                    end
                end

                %Save data
                if(WITHIN_TOLERANCE==2)
                    DATA.ResultArray.Time = [DATA.ResultArray.Time current_time];
                    DATA.ResultArray.RPM = [DATA.ResultArray.RPM RPM];
                    DATA.ResultArray.Trust = [DATA.ResultArray.Trust TRUST];
                    DATA.ResultArray.Torque = [DATA.ResultArray.Torque TORQUE];
                    DATA.ResultArray.Vbat = [DATA.ResultArray.Vbat VBAT];
                    DATA.ResultArray.Current = [DATA.ResultArray.Current CURRENT];
                    DATA.ResultArray.AmbientTemp = [DATA.ResultArray.AmbientTemp T_AMBIENT];
                    DATA.ResultArray.MotorTemp = [DATA.ResultArray.MotorTemp T_MOTOR];
                    DATA.ResultArray.THROTTLE = [DATA.ResultArray.THROTTLE round(controller.throttle)];
                    DATA.ResultArray.PITCH = [DATA.ResultArray.PITCH round(controller.pitch)];

                    %Check how long it has been within tolerance
                    total_data = 24*3600*(current_time-DATA.ResultArray.Time(1));
                    if(total_data>=STEP_DURATION)
                        %Remove extra data older than STEP_DURATION
                        for i=1:numel(DATA.ResultArray.Time)
                            time = DATA.ResultArray.Time(i);
                            delta = 24*3600*(current_time-time);
                            if(delta>=STEP_DURATION)
                                last_valid = i;
                            end
                        end
                        if(last_valid > 1)
                            DATA.ResultArray.Time(1:last_valid-1)=[];
                            DATA.ResultArray.RPM(1:last_valid-1)=[];
                            DATA.ResultArray.Trust(1:last_valid-1)=[];
                            DATA.ResultArray.Torque(1:last_valid-1)=[];
                            DATA.ResultArray.Vbat(1:last_valid-1)=[];
                            DATA.ResultArray.Current(1:last_valid-1)=[];
                            DATA.ResultArray.AmbientTemp(1:last_valid-1)=[];
                            DATA.ResultArray.MotorTemp(1:last_valid-1)=[];
                            DATA.ResultArray.THROTTLE(1:last_valid-1)=[];
                            DATA.ResultArray.PITCH(1:last_valid-1)=[];
                        end

                        %Check that temperature has stabilized within tolerance
                        MIN_TEMP = min(DATA.ResultArray.MotorTemp);
                        MAX_TEMP = max(DATA.ResultArray.MotorTemp);
                        if(MAX_TEMP-MIN_TEMP<TEMP_TOLERANCE || ~SETTLE_TEMPERATURE)
                            TEST_FINISHED = 'DONE';
                            disp('Test completed sucessfully');
                        else
                            MainMessage = ['Waiting for temperature to stabilize:' 32 num2str(MAX_TEMP-MIN_TEMP) '>' 32 num2str(TEMP_TOLERANCE) '.' 10 13 MainMessage];
                        end
                    else
                        MainMessage = [strcat('Recording data',32,num2str(round(100*total_data/STEP_DURATION)),'%...') 10 13 MainMessage];
                    end
                else
                    DATA.ResultArray.Time = [];
                    DATA.ResultArray.RPM = [];
                    DATA.ResultArray.Trust = [];
                    DATA.ResultArray.Torque = [];
                    DATA.ResultArray.Vbat = [];
                    DATA.ResultArray.Current = [];
                    DATA.ResultArray.AmbientTemp = [];
                    DATA.ResultArray.MotorTemp = [];
                    DATA.ResultArray.THROTTLE = [];
                    DATA.ResultArray.PITCH = [];
                end

                if(time_since_start>TIME_LIMIT)
                    TEST_FINISHED = ['TIMOUT:' 32 num2str(TIME_LIMIT) 's'];
                end

                MainMessage = [MainMessage 10 13 'Currently ', num2str(RPM) ,'rpm and',32,num2str(TRUST),'g of trust.'];

                %Output
                THROTTLE = round(controller.throttle);
                PITCH = round(controller.pitch);
            end
            
            %Save data and decide what to do next
            if(~isempty(TEST_FINISHED) && STEP ~= 1)
                save_trust_data(FILE,index,TEST_FINISHED,DATA.targetRPM,DATA.targetTrust,DATA.ResultArray);
                parameters_file = [FILE.pathstr '\' FILE.name];
                save(parameters_file); %Save workspace variables
                disp(TEST_FINISHED);
                index = index + 1;
                if(index>size(FILE.tests_list,1))
                    STEP = -1;
                    MainMessage = 'All tests done';
                else
                    STEP = 2;
                    DATA.MotorColdCount = 0;
                end
            end
    end
end

Message = MainMessage;
%Message = strcat(num2str(Percentage),'%',32,'(',minutes,num2str(Time_left),'s remaining)',10,13,MainMessage);

end
