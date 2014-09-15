function [ cycleTime ] = protocol_get_cycleTime()
global protocol_STATE
cycleTime = protocol_STATE.M.MSP_STATUS.cycleTime;
end

