%%%%%%Makes a table summarizing the results

%Get all the files to process
path = 'D:\Dropbox\Charles Dominic\Technical\Trust Test Jig\Test Results\Main';
old_folder = cd([path '\Tests']);
csv_files = dir('*.csv');
cd(old_folder);

COMPLETE_DATA = {};
TRUSTs = [];
MOTORs = {};
BLADEs = {};

%Get data for all the files
for file_num = 1:numel(csv_files)
    FILEDATA = [];
    
    %Gets the complete test data labelled as DONE into array
    filename = [path '\Tests\' csv_files(file_num,1).name];
    fileID = fopen(filename);
    index = 0;
    line = 0;
    is_table = 0;
    number_read = 0;

    %Parse the whole file
    while(line~=-1)
        %Read whole line
        index = index + 1;
        line = fgetl(fileID);
        if(~isempty(line))
            if(line~=-1)
                %   1       2           3        4        5      6    7        
                %STATUS	TargetRPM	TargetTrust	Date	Time	RPM	Trust	
                %   8     9        10        11         12          13       14
                %Torque	Vbat	Current	AmbientTemp	MotorTemp	THROTTLE	PITCH
                if(is_table==0)
                    %Find the header row
                    DATA = textscan(line,'%s %s','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'Motor:'))
                        MOTORs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'Blade:'))
                        BLADEs{file_num} = DATA{1,2}{1,1};
                    end
                    if(strcmp(DATA{1,1}{1,1},'STATUS'))
                        is_table = 1;
                    end
                else
                    %Check if status is DONE
                    DATA = textscan(line,'%s %f %f %s %s %f %f %f %f %f %f %f %f %f','Delimiter',',');
                    if(strcmp(DATA{1,1}{1,1},'DONE'))
                        %Save data
                        vals = [DATA{1,2}(1),DATA{1,3}(1)];
                        for i=6:14
                            vals = [vals DATA{1,i}(1)];
                        end
                        FILEDATA = [FILEDATA; vals];
                        TRUSTs = [TRUSTs DATA{1,3}(1)];
                    end
                end
            end
        end
    end
    
    fclose(fileID);
    COMPLETE_DATA{file_num}=FILEDATA;
end

%Get the list of trusts
TRUSTs = unique(sort(TRUSTs));

%Sort by blade alphabetically
[~,ORDER]=sort(BLADEs);

%For each test, and each trust, get the best efficiency in w/g
DISPLAY{1,1}='g/w';
DISPLAY{1,2}='Motor';
DISPLAY{1,3}='Blade';
for order_num=1:numel(COMPLETE_DATA)
    test_num = ORDER(order_num);
    [pathstr, name, ext] = fileparts(csv_files(test_num,1).name);
    DISPLAY{order_num+1,1} = name;
    DISPLAY{order_num+1,2} = MOTORs{test_num};
    DISPLAY{order_num+1,3} = BLADEs{test_num};
    for trust = 1:numel(TRUSTs)
        DISPLAY{1,trust+3}=strcat(num2str(TRUSTs(trust)),'g');
        DATA = COMPLETE_DATA{1,test_num};
        
        %Only keep the lines for current trust
        DATA(DATA(:,2)~=TRUSTs(trust),:)=[];
        
        %Get the watts/g
        trustvals = DATA(:,4);
        voltages = DATA(:,6);
        currents = DATA(:,7)*0.001;
        efficiency = trustvals./(voltages.*currents);
        
        DISPLAY{order_num+1,trust+3}=max(efficiency);
    end
end

cell2csv([path '\Summary.csv'],DISPLAY);
DISPLAY