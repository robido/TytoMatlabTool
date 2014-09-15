function protocol_init()
%PROTOCOL_INIT

GLOBAL protocol_STATE
P = protocol_STATE;

%Populate default values
P.M.MSP_STATUS.RENEW = 1;
P.M.MSP_STATUS.cycleTime = 0;
P.M.MSP_STATUS.cycleTime = 0;

protocol_STATE = P;
end

