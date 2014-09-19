function STATE = protocol_update_state( cmdMSP, inBuf, STATE )
%PROTOCOL_UPDATE_STATE
switch cmdMSP
 case 101 %MSP_STATUS
    STATE.M.MSP_STATUS.cycleTime = typecast(inBuf(1:2),'uint16');
    STATE.M.MSP_STATUS.i2c_errors_count = typecast(inBuf(3:4),'uint16');
 case 102 %MSP_RAW_IMU
     for i=1:3
        accSmooth(i) = typecast(inBuf(2*i-1:2*i),'int16');
        gyroData(i) = typecast(inBuf(2*i+5:2*i+6),'int16');
        magADC(i) = typecast(inBuf(2*i+11:2*i+12),'int16');
        %gyroADC(i) = typecast(inBuf(4*i+15:4*i+18),'int32');
        %accADC(i) = typecast(inBuf(2*i+29:2*i+30),'int16');
     end
    STATE.M.MSP_RAW_IMU.accSmooth = accSmooth;
    STATE.M.MSP_RAW_IMU.gyroData = gyroData;
    STATE.M.MSP_RAW_IMU.magADC = magADC;
    %STATE.M.MSP_RAW_IMU.gyroADC = gyroADC;
    %STATE.M.MSP_RAW_IMU.accADC = accADC;
 case 254 %MSP_DEBUG
    debug(1) = typecast(inBuf(1:2),'int16');
    debug(2) = typecast(inBuf(3:4),'int16');
    debug(3) = typecast(inBuf(5:6),'int16');
    debug(4) = typecast(inBuf(7:8),'int16');
    STATE.M.MSP_DEBUG.debug = debug;
 otherwise   
end