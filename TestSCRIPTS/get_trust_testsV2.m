function [ PITCH_VALUES ] = get_trust_testsV2( file, PITCH_VALUES )

test = [];

fileID = fopen(file);
index = 0;

line = 0;
is_table = 0;
while(line~=-1)
    %Read whole line
    index = index + 1;
    line = fgetl(fileID);
    if(line~=-1)
        DATA = textscan(line,'%s %s %s %f %f','Delimiter',',');
        if(is_table==0)
            %Find the header row
            if(strcmp(DATA{1,1}{1,1},'STATUS'))
                is_table = 1;
            end
        else
            %Check if status is not empty
            if(~isempty(DATA{1,1}{1,1}))
                %Save as test done
                test = [test; DATA{1,5}(1)];
            end
        end
    end
end

%Remove the tests done from the list
test = unique(test);
PITCH_VALUES(ismember(PITCH_VALUES, test))=[];

