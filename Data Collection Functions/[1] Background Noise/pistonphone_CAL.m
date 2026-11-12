%function PistonPhoneCalibration_Multi
% This function is designed for calibrating multiple PCB microphones using
% the pistonphone technique. It will repeat for each channel and save the
% calibrated sensitivity.
%
% The GRAS 1/4" should be 0.0036 V
% The PCB 1/4" should be 0.050 V
% The GRAS 1/2" should be 0.050 V
% -------------------------------------------------------------------------

% Inputs
P_a = 101.6;  % Atmospheric pressure [kPa]
mic_channels = 4;  % Channel(s) that are connected to the mic(s)
mic_PXIcard = 'PXI1Slot3';  % PXI card in use
meas_type = 'Voltage';  % 'Voltage' for 1/4" GRAS, 'IEPE' for PCB and 1/2" GRAS (i.e. if a signal conditioner is used)
%  meas_type = 'Voltage';
% Variables
t_samp = 60;
f_s = 2^16;
num_bin = 100;
filt_delay = 6;

cal_settings = {[' Sampling time = ', num2str(t_samp),' s']; ...
    [' Sampling frequency = ', num2str(f_s), ' Hz']; ...
    [' Atmospheric pressure = ', num2str(P_a), ' hPa']; ...
    [' Number of ensemble bins = ', num2str(num_bin)]; ...
    [' Filter delay = ', num2str(filt_delay), ' s']};

%% Pistonphone SPL levels

% Volume correction
  % For the 1/4" microphones,  delPv = 0
  % For 1/2" microphone, use the correction provided in the pistonphone
  % manual (-0.014 dB for 40AE microphone)
delPv = 0;  % [dB]

% Pressure correction
delPp = 20 * log10(P_a / 101.3);  % [dB]; reference pressure is = 101.3 kPa

% Effective SPL for the Pistonphone
SPL = 114 + delPv + delPp;

%% Open DAQ connection
warning('off')
s1 = daq.createSession('ni');  % Open DAQ connection

% Add channels
s1.addAnalogInputChannel(mic_PXIcard, mic_channels, meas_type);

% Set capture parameters
s1.Rate = f_s;  % Set sampling rate
s1.DurationInSeconds = t_samp + filt_delay;  % Add filter delay to sampling duration
actual_rate = get(s1, 'Rate');

%% Collect data
loc = {};
for j = 1:length(mic_channels)
    prompt = ['Connect the Pistonphone to Channel ', num2str(mic_channels(j)) , ', then type location and press enter:   '];
    loc{j} = input(prompt,'s');
    disp('Starting calibration')
    
    % Collect data
    raw_data = startForeground(s1);
    
    % Prepare data for output
    useful_data = actual_rate * filt_delay;  % Calculate how many samples to remove based on the filter start up delay
    
    v_mic = raw_data(useful_data:end,j);  % Voltage output for the channels
    
    % Average data and find sensitivity
    bin_size = floor((actual_rate * t_samp)/num_bin);
    
    V_rms = zeros(1, bin_size);
    
    for i = 1:num_bin
        V_rms = V_rms + rms(v_mic(((i-1) * bin_size + 1):(i*bin_size))' - mean(v_mic(((i-1) * bin_size + 1):(i*bin_size))'));
    end
    
    V_rms = V_rms/num_bin;
    
    Sens(j) = (mean(V_rms)) / (20e-6*10^(SPL/20));
    
    disp(num2str(Sens(j)))
    assignin('base', ['raw',num2str(j)], raw_data);
end

%% Output data
% assignin('base', 'Sensitivity', Sens);
% assignin('base', 'Mic_Locations', loc);
% assignin('base', 'Settings', cal_settings);

delete(s1)