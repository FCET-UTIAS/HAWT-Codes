function [t, actual_rate] = getVoltages_NACA0012(f_s, t_samp, filt_delay)
%%
% input parameters

% f_s = 200000;
% t_samp = 10;
% filt_delay = 3; 
%filename = '7AI_60ms_20200206003';  %  <- dont forget to change me!!!!

%%
disp('Connecting to the DAQ')

% Open DAQ connection
warning('off')

s = daq('ni');  % Open DAQ connection
ch_RMP_1 = 0:15;
ch_RMP_2 = 0:1;
ch_far_field_GRAS_HF = 0;
%ch_far_field_IEPE = 10:15;
% ch_duct_IEPE = 1:3; 
% ch_halfinch_GRAS = 0; 
% ch_testgras = 3; 
%ch_ZOCs = 26:30;

% Add channels
RMP_1 = s.addinput('PXI1Slot2', ch_RMP_1, 'Voltage');
RMP_2 = s.addinput('PXI1Slot3', ch_RMP_2, 'Voltage');
% ref_mic = s.addAnalogInputChannel('PXI1Slot2', ch_halfinch_GRAS, 'IEPE'); 
% duct_IEPE = s.addAnalogInputChannel('PXI1Slot2', ch_duct_IEPE, 'IEPE'); 
far_field_GRAS_HF = s.addinput('PXI1Slot4', ch_far_field_GRAS_HF, 'Voltage');
% far_field_IEPE = s.addAnalogInputChannel('PXI1Slot3', ch_far_field_IEPE, 'IEPE');
% far_field_IEPE = s.addAnalogInputChannel('PXI1Slot4', ch_halfinch_GRAS, 'IEPE'); 
% test_gras = s.addAnalogInputChannel('Dev5', ch_testgras, 'Voltage');
s.AutoSyncDSA = true;                                                       % !!Important!! Synchronize data collection

% Channel names
RMP_1_name = [ "15", "18", "20","21", "22", "23","24", ...
    "25", "26", "28","29", "ZP+1", "ZP+2", "ZP-2", "ZS+1","ZS+2"];
RMP_2_name = [ "ZS-1","ZS-2"];

far_field_GRAS_HF_name = ["A"];
% far_field_IEPE_name = ["B", "B'", "C", "C'", "D", "D'"];
% duct_IEPE_name = ["E'", "F'", "G'"]; 
% ref_name = "R"; 

names_all = [RMP_1_name, RMP_2_name, far_field_GRAS_HF_name];
% names_all = [RMP_1_name, RMP_2_name, far_field_GRAS_HF_name, far_field_IEPE_name];
% names_all = [ref_name, duct_IEPE_name, far_field_GRAS_HF_name, far_field_IEPE_name]; 
% names_all = [far_field_GRAS_HF_name, far_field_IEPE_name];
% names_all = far_field_GRAS_HF_name;
% for i = 1:length(ch_RMP_1)
%     RMP_1(i).Name = RMP_1_name(i);
% end
% for i = 1:length(ch_RMP_2)
%     RMP_2(i).Name = RMP_2_name(i);
% end
% for i = 1:length(ch_far_field_GRAS_HF)
%     far_field_GRAS_HF(i).Name = far_field_GRAS_HF_name(i);
% end
% for i = 1:length(ch_far_field_GRAS_HF)
%     far_field_IEPE(i).Name = far_field_IEPE_name(i);
% end

% Set capture parameters
s.Rate = f_s;  % set sampling rate
% s.DurationInSeconds = t_samp + filt_delay;  % add filter delay to sampling duration
actual_rate = get(s, 'Rate');  % get actual sampling rate of data based on DAQ limits
% addTriggerConnection(s, "PXI1Slot2/PXI_Trig0", "PXI1Slot3/PXI_Trig0", "StartTrigger");
% addTriggerConnection(s, "PXI1Slot2/PXI_Trig0", "PXI1Slot4/PXI_Trig0", "StartTrigger");
% addTriggerConnection(s, "PXI1Slot2/PXI_Trig0", "Dev5/PXI_Trig0", "StartTrigger");

%%
disp('Collecting data')
% Collect data
% [data, time] = startForeground(s);

DAQ = read(s, seconds(t_samp + filt_delay));
time = DAQ.Time;
data = DAQ.Variables;

%%
% Prepare data for output
% useful_data = actual_rate * filt_delay;  % calcualte how many samples to remove based on the filter start up delay
useful_data = floor(actual_rate * filt_delay) + 1;                  % calcualte how many samples to remove based on the filter start up delay

voltage = data(useful_data:end,:);                        % voltage output for the channels
t_stamp = time(useful_data:end,:);                      % timestamp for each of the samples

t_stamp = seconds(t_stamp); 

% disp('Finished data collection & saving data')

in_table = [t_stamp, voltage];
t = array2table(in_table);
t.Properties.VariableNames = ['Time', names_all];
% save(filename, 'v_mic', 'f_s', 't_samp', 't_stamp', 'filt_delay');

%%
% Clear DAQ from system
delete(s);
clear s


%disp('Test Complete')




