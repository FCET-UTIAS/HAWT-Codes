function [v_offset,fileName]=ZOCcalibration(TempCelcOnline,PresKPascOnline)

%---------------------------------------------------------------------------
% Function to calibrate (zero) the ZOC pressure modules
% Description: Measures the air temperature with the Baratron DAQ, then
% measures the zero offset of the ZOC pressure modules with zoc_offset
% (40 kHz, 0.1 s per sensor, 2 loops). Plots the mean offset pressure
% (psi) for each of the four modules (M270, M276, M275, M267). Before
% saving, the previous ZOCcalibration files in CalibrationData\ZOCcalibration
% are moved to its Legacy folder. The whole workspace is then saved as
% ZOCcalibration<date_time>.mat, with the figure saved as a .fig file of the
% same name. The folder is reached with a relative path, so run this from
% the ExCamp1 folder. The temperature and pressure inputs are not used in
% the calculation; they are saved in the .mat file with the other variables.
%
% INPUTS: TempCelcOnline  - current atmospheric temperature (deg C)
%         PresKPascOnline - current atmospheric pressure (kPa)
% OUTPUTS: v_offset - ZOC zero offset for each channel (columns are the
%                     modules)
%          fileName - name of the saved .mat file
%
% FUNCTIONS: (functions this function uses)
%   Meas_T_PS  - reads the air temperature (T) with the Baratron DAQ
%   zoc_offset - measures the zero offset of the ZOC modules and returns
%                v_offset, the serial numbers and an offset status struct
%   Folders added to the path: AWTcontrol, and the ZOC and CAL_files_gains_only
%   folders under Subfunctions\ZOC
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

disp("===============================================")
disp("===============ZOC calibration=================")
disp("===============================================")

f_s = 40000;
time_per_sensor_in_a_loop = 0.1;
no_of_loops = 2;

f_s_temperature = 4000;
t_s_temperature = 30;

disp("Measuring temperature")
addpath("I:\ExCamp1\AWTcontrol")
[T,~] = Meas_T_PS(f_s_temperature,t_s_temperature);
disp(strcat("Measured temperature: ",num2str(T)," deg"))

addpath("I:\ExCamp1\Subfunctions\ZOC\NRC_ZOCs_Cal_files\CAL_files_gains_only\")
addpath("I:\ExCamp1\Subfunctions\ZOC")

%% Get ZOC offset
[v_offset,serialnums,zoc_offset_status] = zoc_offset(f_s,time_per_sensor_in_a_loop,no_of_loops);

TempCelcOnline=TempCelcOnline;
PresKPascOnline=PresKPascOnline;



%{
figure;
subplot(2,2,1)
bar(v_offset(:,1))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')

subplot(2,2,2)
bar(v_offset(:,2))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')

subplot(2,2,3)
bar(v_offset(:,3))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')

subplot(2,2,4)
bar(v_offset(:,4))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')



%}

ZOCoffset=figure;
subplot(2,2,1)
bar(zoc_offset_status.offset_p_mean(:,1))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')

subplot(2,2,2)
bar(zoc_offset_status.offset_p_mean(:,2))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')

subplot(2,2,3)
bar(zoc_offset_status.offset_p_mean(:,3))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')

subplot(2,2,4)
bar(zoc_offset_status.offset_p_mean(:,4))
ylabel('Pressure (psi)','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')

date_time = datestr(now,'yyyy-mm-dd_HH-MM');
OldPath=cd('CalibrationData/ZOCcalibration');
status=movefile(strcat('ZOCcalibration*'), 'Legacy');
fileName=strcat('ZOCcalibration',date_time,'.mat');
save(fileName);
savefig(strcat('ZOCcalibration',date_time,'.fig'))
cd(OldPath)
%close(ZOCoffset)

end
