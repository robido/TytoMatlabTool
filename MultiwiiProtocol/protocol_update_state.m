function protocol_update_state( cmdMSP, inBuf )
%PROTOCOL_UPDATE_STATE

global protocol_STATE
P = protocol_STATE;

switch cmdMSP
 case 101 %MSP_STATUS
    P.M.MSP_STATUS.cycleTime = typecast(inBuf(1:2),'uint16');
    clc
    disp(strcat('cycleTime:',num2str(P.M.MSP_STATUS.cycleTime)));
    P.M.MSP_STATUS.i2c_errors_count = typecast(inBuf(3:4),'uint16');
 case 254 %MSP_DEBUG
    debug(1) = typecast(inBuf(1:2),'int16');
    debug(2) = typecast(inBuf(3:4),'int16');
    debug(3) = typecast(inBuf(5:6),'int16');
    debug(4) = typecast(inBuf(7:8),'int16');
    P.M.MSP_DEBUG.debug = debug;
 otherwise   
end

protocol_STATE = P;