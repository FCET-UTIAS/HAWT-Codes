function [v_offset, serialnums,zoc_offset_status] = zoc_offset(f_s,time_per_sensor_in_a_loop,no_of_loops)

% ZOC offset should be measured at least twice a day. You can confirm
% offset drift any time in the day by measuring offset and comparing to a
% previous measurement. To take offset, let the ref port on all modules and
% the measurement ports be both opened to the same atmospheric conditions.

[offset_read_back, offset_rawVoltage, offset_t_stamp, v_offset, offset_std, serialnums] = ZOC_quick_scan_2(f_s,time_per_sensor_in_a_loop,no_of_loops);
zocs = zoc_setupzocs_NRC(serialnums);
v_gain = zeros(size(v_offset));
for i = 1:length(serialnums)
    v_gain(:,i) = eval(strcat('zocs.',serialnums{i},'.calibration'));
end

%rmpath("NRC_ZOCs_Cal_files\CAL_files_gains_only\")
zoc_offset_status.offset_p_mean = v_offset.*v_gain;
zoc_offset_status.offset_read_back=offset_read_back;
zoc_offset_status.offset_rawVoltage=offset_rawVoltage;
zoc_offset_status.offset_t_stamp=offset_t_stamp;
zoc_offset_status.v_offset=v_offset;
zoc_offset_status.offset_std=offset_std;
zoc_offset_status.serialnums=serialnums;
zoc_offset_status.v_gain=v_gain;
end