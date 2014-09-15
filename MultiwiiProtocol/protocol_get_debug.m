function debug = protocol_get_debug(STATE)

try
    debug = cast(STATE.M.MSP_DEBUG.debug,'double');
catch
    debug = [0 0 0 0];
end

