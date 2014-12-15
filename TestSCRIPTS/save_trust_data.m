function save_trust_data(FILE,index,STATUS,targetRPM,targetTrust,DATA)

file = FILE.file;
FIELDs = fieldnames(DATA)';

if exist(file, 'file') ~= 2
    %Create the header
    fid = fopen(file, 'w') ;
    fprintf(fid, 'Main motor test data\nCheck .mat file with this one for parameters\nMotor:\nESC:\nESC config/firmware:\nBlade:\nMATLAB commit version:\nRelay board commit version:\nNanowii commit version:\nComment:\n\n') ;
    fprintf(fid, '%s,', 'STATUS,TargetRPM,TargetTrust,Date,Time') ;
    for i=2:numel(FIELDs)
        fprintf(fid, '%s,', FIELDs{i}) ;
    end
    fprintf(fid, '\n') ;
    fclose(fid);
else
    %Add the result to the specific line
    real_index = FILE.tests_list(index,1);
    A = regexp( fileread(file), '\n', 'split');
    c = fix(clock);
    timestr = strcat(num2str(c(4)),'h',num2str(c(5)),'m',num2str(c(6)),'s');
    A{real_index} = sprintf('%s,%f,%f,%s,%s,',STATUS,targetRPM,targetTrust,date,timestr);
    for i=2:numel(FIELDs)
        values = getfield(DATA,FIELDs{i});
        from = round(numel(values)/3);
        to = numel(values);
        if(numel(values)>20)
            try
                values = values(1,from:to); %Trim the first 1/3 of data as may not be fully stable.
            catch
            end
        end
        value = mean(values);
        A{real_index} = sprintf('%s%f,', A{real_index}, value) ;
    end
    fid = fopen(file', 'w'); %rewrite the whole file
    fprintf(fid, '%s\n', A{:});
    fclose(fid);
end

end

