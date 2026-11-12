function [read_back, rawVoltage, t_stamp, v_mean, v_std, p_mean] = getZOC_pressure_2(f_s,t_s,v_offset)
disp("===============================================")
disp("===============ZOC measurement=================")
disp("===============================================")

[read_back,  rawVoltage, t_stamp, v_mean, v_std, serialnums] = ZOC_serial_scan_2(f_s,t_s);
zocs = zoc_setupzocs_NRC(serialnums);

v_gain = zeros(size(v_mean));
for i = 1:length(serialnums)
    v_gain(:,i) = eval(strcat('zocs.',serialnums{i},'.calibration'));
end

p_mean = (v_mean - v_offset).*v_gain; 
end