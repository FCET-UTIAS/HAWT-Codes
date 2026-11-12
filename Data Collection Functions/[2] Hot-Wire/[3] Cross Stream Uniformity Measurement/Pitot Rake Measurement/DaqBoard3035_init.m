function [ai_pres,ActualRate_pres] = DaqBoard3035_init(sr_pres,ts_pres,NC_pres)
% AUTHOR: Unknown
% Revision: NC - Unknown - Unknown
% Revision: A - Blago Hristovski - 10 JAN 2020
%           Updated Author, Revision, and Description, Input sections
%           Updated comments
%           
% 
% Description: This function is used for initializing the ioTech DAQ
%              Board/USB 3000 Series device.
% 
% Inputs: 
%  - sr_pres: Sampling rate
%  - ts_pres: Sampling time
%  - NC_pres: Number of channels to sample
% 
% 
% 
iotInfo = daqhwinfo('iotdaq');                                             % Obtain hardware information
ai_pres = analoginput('iotdaq', 1);                                        % Initiate analog input object
chans_pres = addchannel(ai_pres,0:NC_pres-1);                              % This should add the first 64 analog input channels
ai_pres.Channel(1:NC_pres).InputRange = [-5 5];                            % Set input range of voltage (-5V to 5 V)
dio = digitalio('iotdaq',1);                                               % Initiate digital i/o object

ai_pres.samplerate        = sr_pres;                                       % Set the sample rate
ai_pres.samplespertrigger = ts_pres*sr_pres;                               %
ai_pres.triggertype       = 'immediate';                                   %
ai_pres.loggingmode       = 'memory';                                      %

set(ai_pres,'SampleRate', sr_pres);                                        % Set the sample rate
set(ai_pres,'TriggerDelay',0.5)                                            % Delays logging for time after trigger is set
set(ai_pres,'TriggerDelayUnits','Seconds')
ActualRate_pres = get(ai_pres,'SampleRate');                               % Verify the sample rate

%Inititalize type of analog input signal (single ended in our case)
ai_pres.InputType = 'SingleEnded';

aiInfo = daqhwinfo(ai_pres); %Verify that all changes have been made properly

seChans = aiInfo.SingleEndedIDs;
%Make sure the analog input channels are detected
if aiInfo.TotalChannels < 1
    delete(ai);
    error('No analog input channels found')
end
end