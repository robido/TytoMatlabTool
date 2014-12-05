function save_trust_data(FILE,STATUS,targetRPM,targetTrust,DATA)

path = FILE.path;
name = FILE.name;
ext = FILE.ext;
file = [path '\' name ext];
FIELDs = fieldnames(DATA)';

if exist(file, 'file') ~= 2
    %Create the header
    fid = fopen(file, 'w') ;
    fprintf(fid, 'Main motor test data\nMotor:\nESC:\nESC config/firmware:\nBlade:\nMATLAB commit version:\nRelay board commit version:\nNanowii commit version:\nComment:\n\n') ;
    fprintf(fid, '%s,', 'STATUS,TargetRPM,TargetTrust') ;
    for i=2:numel(FIELDs)
        fprintf(fid, '%s,', FIELDs{i}) ;
    end
    fprintf(fid, '\n') ;
    fclose(fid);
end
fid = fopen(file, 'a') ;
fprintf(fid, '%s,%f,%f,', STATUS,targetRPM,targetTrust) ;
for i=2:numel(FIELDs)
    values = getfield(DATA,FIELDs{i});
    value = mean(values);
    fprintf(fid, '%f,', value) ;
end
fprintf(fid, '\n') ;
fclose(fid);

end

