function i2c_errors = protocol_get_i2c_errors(STATE)
try
    i2c_errors = cast(STATE.M.MSP_STATUS.i2c_errors_count,'double');
catch
    i2c_errors = 0;
end
end

