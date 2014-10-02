%Change folder
currentFolder = pwd;
[folder, name, ext] = fileparts(mfilename('fullpath'));
cd(folder);

%Compile
warning('off','MATLAB:dispatcher:ShadowedMEXExtension');
mex OscMx.c

%Open it
OscMx(2);
OscMx(4);

%Go back to old folder
cd(currentFolder);