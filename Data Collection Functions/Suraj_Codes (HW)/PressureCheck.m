%function [] = PressureCheck()
clear
clc
delete(instrfindall)

P_gain_u        = 0.75 * 133.33;
Pambient_kPa    = 100.3;
t_samp          = 60;
f_s             = 1e5;

disp('Pitot offset measurement...');
CHANNELS        = [16, 20];

% Configure the data acquisition
ses             = daq.createSession('ni');
ses.addAnalogInputChannel('Dev7',CHANNELS, 'Voltage');

set(ses.Channels,'TerminalConfig','Differential');

ses.Channels(1).Range   = [-1 1];
ses.Channels(2).Range   = [-1 1];

ses.DurationInSeconds   = t_samp;
ses.Rate                = f_s;
ActualRate              = f_s;
[data, time]            = ses.startForeground();

P_offset_v_u(1)         = mean(data(:,1));
P_offset_v_u(2)         = mean(data(:,2));

disp('Run the tunnel');
ask = input('Continue?');

% Clear DAQ from system
delete(ses);
clear ses chans CHANNELS data;

P_atm_mmHg              = Pambient_kPa *1e3 *0.0075;
Tset_C                  = Meas_TC;                                            % TCSession_Omega_FCETdaq(1, 1000);
[rho_kgpm3, mu_Pas,~,~] = fluid_prop(Tset_C, P_atm_mmHg);                     % determine fluid properties

CHANNELS = [16, 20];

% Configure the data acquisition
ses = daq.createSession('ni');
ses.addAnalogInputChannel('Dev7',CHANNELS, 'Voltage');

set(ses.Channels,'TerminalConfig','Differential');

ses.Channels(1).Range   = [-10 10];
ses.Channels(2).Range   = [-10 10];

ses.DurationInSeconds   = t_samp;
ses.Rate                = f_s;
ActualRate              = f_s;
[data, time]            = ses.startForeground();

pt_e_u(1)               = mean(data(:,1));
pt_e_u(2)               = mean(data(:,2));

[Up(1), ~, ~, ~]        = get_pt_v(pt_e_u(1), P_offset_v_u(1), P_gain_u, rho_kgpm3);
[Up(2), ~, ~, ~]        = get_pt_v(pt_e_u(2), P_offset_v_u(2), (P_gain_u), rho_kgpm3);

% Up1_mps(1) = Up(1);
% Up1_mps(1) = Up(2);


