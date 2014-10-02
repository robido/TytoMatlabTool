function available = serial_is_available( captureFileID )
%SERIAL_IS_AVAILABLE Summary of this function goes here
%   Detailed explanation goes here
available = ~feof(captureFileID);

end

