function save_trust_dataV2(FILE,STATUS,DATA)

file = FILE.file;
FIELDs = fieldnames(DATA)';

if exist(file, 'file') ~= 2
    %Create the header
    fid = fopen(file, 'w') ;
    fprintf(fid, 'Main motor test V2 data\nCheck .mat file with this one for parameters\nMotor:\nESC:\nESC config/firmware:\nBlade:\nRatio:\nMATLAB commit version:\nRelay board commit version:\nNanowii commit version:\nComment:\n') ;
    fprintf(fid, '%s,', 'STATUS,Date,Time') ;
    for i=1:numel(FIELDs)
        fprintf(fid, '%s,', FIELDs{i}) ;
    end
    fclose(fid);
else
    %Add the results
    A = regexp( fileread(file), '\n', 'split');
    last_row = A{numel(A)};
    last_row(last_row==',')=[]; %Remove commas
    if(isempty(last_row))
        real_index = numel(A)-1;
    else
        real_index = numel(A);
    end
    c = fix(clock);
    timestr = strcat(num2str(c(4)),'h',num2str(c(5)),'m',num2str(c(6)),'s');
    to = numel(getfield(DATA,FIELDs{1}));
    for data_index = 1:to
        if(data_index == to)
            stat_message = STATUS;
        else
            stat_message = 'DONE';
        end
        A{real_index+data_index} = sprintf('%s,%s,%s,',stat_message,date,timestr);
        for i=1:numel(FIELDs)
            values = getfield(DATA,FIELDs{i});
            value = values(data_index);
            A{real_index+data_index} = sprintf('%s%f,', A{real_index+data_index}, value) ;
        end
    end
    fid = fopen(file', 'w'); %rewrite the whole file
    fprintf(fid, '%s\n', A{:});
    fclose(fid);
end

end

