function [ debugval ] = protocol_get_debug(ID)
global protocol_STATE
try
    debug = protocol_STATE.M.MSP_STATUS.cycleTime;
    debugval = debug(ID);
catch
    debugval = 0;
end

