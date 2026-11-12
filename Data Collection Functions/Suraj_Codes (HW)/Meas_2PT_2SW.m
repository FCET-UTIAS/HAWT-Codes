function [ PTdata_u, SW_1data_u, PTdata_d, SW_2data_d, del_P, ActualRate ] = Meas_2PT_2SW( f_s, t_samp, Nfft )

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer, u for upstream, d
% for downstream
% SWdata: measurements acquired from hot-wire, u for upstream, d
% for downstream
% ActualRate: the sampling rate that was used by the DAQ board

CHANNELS = [0 1 2 3 4 5 6 7];

% Configure the data acquisition
ai = analoginput('nidaq','Dev7');
chans = addchannel(ai,CHANNELS);

set(ai,'InputType','Differential');
set(ai,'BufferingMode','Auto');
set(chans(1),'InputRange',[-10 10]);
set(chans(2),'InputRange',[-10 10]);
set(chans(3),'InputRange',[-10 10]);
set(chans(4),'InputRange',[-10 10]);
set(chans(5),'InputRange',[-10 10]);
set(chans(6),'InputRange',[-10 10]);
set(chans(7),'InputRange',[-10 10]);
set(chans(8),'InputRange',[-10 10]);

ActualRate = setverify(ai,'SampleRate', f_s); % Actual sampling rate may differ from f_s, this returns value set
Nsampmin = t_samp*ActualRate;     % minimum number of samples at this rate
nrec = ceil(Nsampmin/Nfft);     % generate an integer number of FFT records
Nsamp = Nfft*nrec;

% Nsamp = ceil(t_samp*ActualRate);
set(ai,'TriggerType','Manual');
set(ai,'SamplesPerTrigger',Nsamp);
start(ai);
trigger(ai);

data = getdata(ai);
PTdata_u = data(:,7);
SW_1data_u = data(:,1);
PTdata_d = data(:,8);
SW_2data_d = data(:,2);
del_P = data(:,5);

% Clear DAQ from system
delete(ai);
clear ai chans CHANNELS;

end

