function plot_values = protocol_get_plot_values(STATE,Plot_Selections)

PLOT_LIST = protocol_get_plot_list();

plot_values = [0 0 0];
number_of_selections = size(Plot_Selections,2);
for i=1:min(3,number_of_selections) %Max of 3 plots
    ID = PLOT_LIST{Plot_Selections(i)}.ID;
    ITEM = PLOT_LIST{Plot_Selections(i)}.ITEM;
    
    switch ID
        case 0
            plot_values(i) = STATE.SERIAL_STATUS.serial_Hz;
        case 101
            plot_values(i) = STATE.M.MSP_STATUS.cycleTime;
        case 102
            axis = mod(ITEM-1,3)+1;
            if(ITEM<4)
                imu_val = STATE.M.MSP_RAW_IMU.accSmooth;
            else
                if (ITEM<7)
                    imu_val = STATE.M.MSP_RAW_IMU.gyroData;
                else
                    imu_val = STATE.M.MSP_RAW_IMU.magADC;
                end
            end
            plot_values(i) = imu_val(axis);
       case 254
            debug = STATE.M.MSP_DEBUG.debug;
            plot_values(i) = debug(ITEM);
    end
end

end

