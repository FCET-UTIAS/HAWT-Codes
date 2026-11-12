function [ P_data, SW_data_orig, ActualRate] = Meas_PT_2SW( f_s, t_samp, Nfft )

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board

P_CHANNELS = [4, 7]; %Pitot tube baratron, Tunnel Baratron
HW_CHANNELS = [14, 15]; %Moving, Stationary


% Configure the data acquisition
ai = daq.createSession('ni');
ch = addAnalogInputChannel(ai, 'Dev5', P_CHANNELS, 'Voltage');
hws = addAnalogInputChannel(ai, 'PXI1Slot3', HW_CHANNELS, 'Voltage'); 

ch(1).TerminalConfig    = 'Differential';
ch(2).TerminalConfig    = 'Differential';
ch(1).Range             = [-10, 10];
ch(2).Range             = [-10, 10];

hws(1).Coupling         = 'DC'; 
hws(2).Coupling         = 'DC'; 
hws(1).Range            = [-10, 10];
hws(2).Range            = [-10, 10];

ai.Rate                 = f_s;

ActualRate              = get(ai, 'Rate');     % Actual sampling rate may differ from f_s, this returns value set
Nsampmin                = t_samp*ActualRate;     % minimum number of samples at this rate
nrec                    = ceil(Nsampmin/Nfft);       % generate an integer number of FFT records
Nsamp                   = Nfft*nrec;

% Nsamp = ceil(t_samp*ActualRate);
ai.NumberOfScans        = Nsamp;
[data,time]             = ai.startForeground;

PTdata                  = data(:,1);
TUNNELdata              = data(:,2); 
SW1_data_orig           = data(:,3);
SW2_data_orig           = data(:,4); 

SW_data_orig = [SW1_data_orig, SW2_data_orig];
P_data = [PTdata, TUNNELdata]; 

% Clear DAQ from system
delete(ai);
clear ai chans P_CHANNELS HW_CHANNELS;

end

