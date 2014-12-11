%Change folder
currentFolder = pwd;
[folder, name, ext] = fileparts(mfilename('fullpath'));
cd(folder);

%Compile
warning('off','MATLAB:dispatcher:ShadowedMEXExtension');
try
mex OscMx.c
catch e
    msgbox('Error: could not compile the oscilloscope dll. Please ensure you are using the 32-bit version of MATLAB, on a Windows PC, and that the MATLAB compiler is setup properly (type "mex - setup" in the command window).');
    rethrow(e);
end

%Open it
OscMx(2);
OscMx(4);

%Go back to old folder
cd(currentFolder);

disp('Oscilloscope dll compiled.');