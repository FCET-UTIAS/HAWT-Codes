function [v_fs_offset,fs_Baratron,ts_Baratron,T,PT_e]=BaratronCalibration
    fs_Baratron = 4000;
    ts_Baratron = 30;
    addpath("I:\ExCamp1\Subfunctions")
    input('Set the valves to ZERO. Press any key to continue');
    pause(0.5)
    disp('BEGIN Pressure Transducer Offset. Wait 30 seconds')
    [T,PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
    v_fs_offset = mean(PT_e);
    disp(['    Initial offset voltage: ' num2str(v_fs_offset,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
    disp('-------------------------------------------------------------------')
    input('Restore the Baratron valve and press any key to continue...')
    
    date_time = datestr(now,'mm-dd-yyyy_HH-MM');

    filename = strcat('BaratronCalibration_' ,date_time);
    OldPath=cd("I:\ExCamp1\CalibrationData\BaratronCalibration");
    status=movefile(strcat('BaratronCalibration_*'), 'Legacy');
    save(strcat(filename,'.mat'));
    cd(OldPath);
    
    disp(strcat("The baratron offset is ",num2str(v_fs_offset),' V.'))
    disp("Make sure to update AWT_Control_Integrated_func.mat")
end