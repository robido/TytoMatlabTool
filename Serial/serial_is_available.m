function available = serial_is_available( s )
%SERIAL_IS_AVAILABLE Summary of this function goes here
%   Detailed explanation goes here
available = get(s,'BytesAvailable');

end

