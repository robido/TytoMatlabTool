function [ test ] = get_trust_tests( file )

test = [];

fileID = fopen(file);
index = 0;

line = 0;
is_table = 0;
while(line~=-1)
    %Read whole line
    index = index + 1;
    line = fgetl(fileID);
    if(~isempty(line))
        if(line~=-1)
            DATA = textscan(line,'%s %f %f','Delimiter',',');
            if(is_table==0)
                %Find the header row
                if(strcmp(DATA{1,1}{1,1},'STATUS'))
                    is_table = 1;
                end
            else
                %Check if status is empty
                if(isempty(DATA{1,1}{1,1}))
                    %Save as test to do
                    test = [test; index, DATA{1,2}(1),DATA{1,3}(1)];
                end
            end
        end
    end
end

end

