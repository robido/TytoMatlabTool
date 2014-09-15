function cycleTime = protocol_get_cycleTime(STATE)
try
    cycleTime = cast(STATE.M.MSP_STATUS.cycleTime,'double');
catch
    cycleTime = 0;
end
end

