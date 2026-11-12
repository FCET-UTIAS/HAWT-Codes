%% PIVDAQsynchronizationTest.m

% The purpose of the function is to see if it is possible to trigger DAQ
% data acquisition from the camera port of PIV.


% Author
% - Satoshi Baba, May 2023

% Modification
% - Satoshi baba: Changed the description: Connect to laser L1 instead of
% the camera signal. Camera is not fired the same time as the laser. The
% exposure starts way ahead.
% 

%{
%% First test: record the signal
DAQname="Dev7";
DAQchannel=21;



%% Data collection 1
% Objective
% - Collect the camera signal
% Instruction
% - Connect the camera signal to channel 1 of the daq. 
% - Run this section
% - Start camera trigger signal

% Start
warning('off')  
s = daq.createSession('ni'); % Open DAQ connection
s.addAnalogInputChannel(DAQname,DAQchannel,'Voltage'); % Add channels

f_s=2^16;
t_s=60;

s.Rate = f_s; % set sampling rate
s.DurationInSeconds = t_s;
f_s_actual = get(s, 'Rate'); % get actual sampling rate of data based on DAQ limits
[v_mic,time] = startForeground(s); % Collect data

disp("Start camera")


%}
%% Data collection 2
% Objective
% - Check if it is possible to trigger the DAQ with the camera signal
% Instruction
% - Connect the camera signal to PFI0. 
% - Run this section
% - Start camera trigger signal
close all

setNum=input('Set number');
planeNum=input('Plane number','s');
input('check dt');

TripStatus="Trip220-4%";
AoAg=5;
ReTarget=1000000;

%PIV_Date_Time='230605_212705'

warning('off')  
s = daq.createSession('ni'); % Open DAQ connection
s.addAnalogInputChannel("PXI1Slot2",[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15],'Voltage'); % Add channels
s.addAnalogInputChannel("PXI1Slot3",[0 1 2 3 4 5 6 7],'Voltage'); % Add channels

f_s=40000;
t_s=1550/10;
%t_s=10/10;

start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');

s.Rate = f_s; % set sampling rate
s.DurationInSeconds = t_s;
f_s_actual = get(s, 'Rate'); % get actual sampling rate of data based on DAQ limits


%% External triggering script
% After running the script, it waits 60 seconds until the code times out 
% and aborts 
s.ExternalTriggerTimeout=60;

% addTriggerConnection
% - Input 1: daq ession name
% - Input 2: trigger source. If you want to sync multiple DAQs, this
%           becomes something else.
% - Input 3: trigger destination (port PFI0 of the daq PXI1Slot2 and Slot3)
% - Input 4: trigger type. In this case the trigger starts the data
%           acquisition.
trigger1=addTriggerConnection(s,'External','PXI1Slot2/PFI0','StartTrigger');
trigger2=addTriggerConnection(s,'External','PXI1Slot3/PFI0','StartTrigger');

disp("running startForeground")
[v_mic,time] = startForeground(s); % Collect data
disp("start PIV")


OldPath=cd('F:\ExperimentalCampaign3\Data\PIV');
FileName=strcat('PIVRMP_U=',num2str(Utarget),'_AoA=',num2str(AoAg),'(geometric)_P=',planeNum,'_',TripStatus,"_Set",num2str(setNum),'_',start_date_time);
save(strcat(FileName,'.mat'))
disp("Don't forget to re-name the folder with the PIV time and move the .mat file into that folder!!")