function [accSmooth gyroData magADC] = protocol_get_IMU(STATE)
try
    accSmooth = STATE.M.MSP_RAW_IMU.accSmooth;
    gyroData = STATE.M.MSP_RAW_IMU.gyroData;
    magADC = STATE.M.MSP_RAW_IMU.magADC;
    %gyroADC = STATE.M.MSP_RAW_IMU.gyroADC;
    %accADC = STATE.M.MSP_RAW_IMU.accADC;
catch
    accSmooth = [0 0 0];
    gyroData = [0 0 0];
    magADC = [0 0 0];
    %gyroADC = [0 0 0];
    %accADC = [0 0 0];
end

