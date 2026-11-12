function [ P_data, SW_data_orig, ActualRate] = Meas_PT_2SW( f_s, t_samp, Nfft )

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board

P_CHANNELS = [0]; %Pitot tube baratron, Tunnel Baratron
HW_CHANNELS = [0 1]; %Moving, Stationary


% Configure the data acquisition
ai = daq.createSession('ni');
ch = addAnalogInputChannel(ai, 'Dev5', P_CHANNELS, 'Voltage');
hws = addAnalogInputChannel(ai, 'PXI1Slot4', HW_CHANNELS, 'Voltage'); 

ch(1).TerminalConfig    = 'Differential';
ch(1).Range             = [-10, 10];

hws(1).Coupling         = 'DC'; 
hws(1).Range            = [-10, 10];
ai.Rate                 = f_s;

ActualRate              = get(ai, 'Rate');     % Actual sampling rate may differ from f_s, this returns value set
Nsampmin                = t_samp*ActualRate;     % minimum number of samples at this rate
nrec                    = ceil(Nsampmin/Nfft);       % generate an integer number of FFT records
Nsamp                   = Nfft*nrec;

% Nsamp = ceil(t_samp*ActualRate);
ai.NumberOfScans        = Nsamp;
[data,time]             = ai.startForeground;

PTdata                  = data(:,1);
SW1_data_orig           = data(:,2);
SW1_data_raw            = data(:,3); 

SW_data_orig = [SW1_data_orig SW1_data_raw];
P_data = [PTdata]; 

% Clear DAQ from system
delete(ai);
clear ai chans P_CHANNELS HW_CHANNELS;

end

