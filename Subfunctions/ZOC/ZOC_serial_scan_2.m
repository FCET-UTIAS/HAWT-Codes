function [read_back, Voltages, time_ZOC, Volt_mean, Volt_std, serialnums] = ZOC_serial_scan_2(f_s,t_s)


dir = 'F:\ExCamp2\Subfunctions\ZOC\NRC_ZOCs_Cal_files';  % Folder where ZOC setup and calibration files are saved

if isfile(strcat(dir,'ZOC_initial_setup_files.mat'))
     ZOC_setup_data = load(strcat(dir,'ZOC_initial_setup_files.mat'));
     ZOC_setup_data = ZOC_setup_data.ZOC_setup_data;
else
    [indx_init,~] = listdlg('PromptString',{'Is it your first time of setting up the ZOCs? ',''},...
    'SelectionMode','single','ListString',{'Yes','No'});
    if indx_init == 1
            ZOC_setup_data = ZOC_init_setup;
            save(strcat(dir,'ZOC_initial_setup_files.mat'),'ZOC_setup_data');
        elseif indx_init == 2 
            disp('You probably saved your ZOC setup data in another folder and with another name other than ZOC_initial_setup_files.mat')
            disp(' ')
            disp('A dialog will open now, please select the mat file that contains your ZOC setup data')
            [baseFileName, folder] = uigetfile('*.mat');
            fullFileName = fullfile(folder, baseFileName);
            ZOC_setup_data = load(fullFileName);
            ZOC_setup_data = ZOC_setup_data.ZOC_setup_data;
            save(strcat(dir,'ZOC_initial_setup_files.mat'),'ZOC_setup_data');
    end
end


device = ZOC_setup_data.analog_setup{1};
d = daq.createSession('ni');
ai = daq.createSession('ni');
for i = 1:length(ZOC_setup_data.analog_setup)-1
    AI_CHANNELS(i) = str2double(ZOC_setup_data.analog_setup{i+1});
end
ai.addAnalogInputChannel(device,AI_CHANNELS,'Voltage');
for i = 1:length(AI_CHANNELS)
    ai.Channels(i).TerminalConfig = char(ZOC_setup_data.terminal_config(ZOC_setup_data.indx_config));
    ai.Channels(i).Coupling = char(ZOC_setup_data.coupling(ZOC_setup_data.indx_coupling));
end

for i = 1:length(ZOC_setup_data.digital_setup)/2
    d.addDigitalChannel(device,ZOC_setup_data.digital_setup{i},'OutputOnly');
end
for i = length(ZOC_setup_data.digital_setup)/2+1:length(ZOC_setup_data.digital_setup)
    d.addDigitalChannel(device,ZOC_setup_data.digital_setup{i},'InputOnly');
end

serialnums = ZOC_setup_data.serialnums;
nzoc = length(serialnums); 
ai.DurationInSeconds = t_s;
ai.Rate = f_s;
ActualRate = ai.Rate;


disp('DAQ Connection Established');
disp(' '); 
disp(' ');


n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
disp('Begin Scan')
disp(' ');
Voltages = zeros(f_s*t_s,length(sensorLogic)/2,nzoc);
read_back = zeros(size(sensorLogic));
for i = 1:length(sensorLogic)/2
    disp(['Scanning Channel ', num2str(i), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
    outputSingleScan(d,flip(sensorLogic(i,:)));
    read_back(i,:) = (inputSingleScan(d));
     confirm = isequal(flip(sensorLogic(i,:)),read_back(i,:));
    if confirm == 0
       disp('Error: The DAQ does not receive the commanded sensor logic')
    end
    [Voltages(:,i,:), time_ZOC] = ai.startForeground();
end

disp(' ')
disp('End Scan')
clc

outputSingleScan(d,sensorLogic(1,:)) %reset channel addressing 
delete(ai)
clear ai
delete(d)
clear d
Volt_mean = reshape(mean(Voltages), [length(sensorLogic)/2, nzoc]);
Volt_std = reshape(std(Voltages), [length(sensorLogic)/2, nzoc]);

disp('Finished data Collection and Saving Data')