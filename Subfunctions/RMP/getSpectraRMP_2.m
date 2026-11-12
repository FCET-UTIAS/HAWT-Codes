function [RMP_PSD, f, RMP_Gpp, p_mic] = getSpectraRMP_2(voltage,f_s,Txy_F,Txy_RMP_name)

% get double sided fft of RMP voltage without 
% windowing or averaging

y = fft(voltage);

% extend RMP gain  to get both sides of the 
% double sided fft 

n =  length(voltage);
ff = f_s*(0:(n/2))/n;
Txy_right_side = interp1(Txy_F,Txy_RMP_name,ff');
Txy_left_side = flip(Txy_right_side(2:end-1));
Txy_full_size = [Txy_right_side;Txy_left_side];

% correct double sided fft with RMP gain

y_corrected = y./abs(Txy_full_size);

% remove NaN values from corrected fft

y_corrected(find(isnan(y_corrected))) = 0;

% Perform ifft to get back pressure in time domain
p_mic = ifft(y_corrected);

% use Pwelch and window functions to get fft of p(t)

Nwindow = 2^14;         % Number of points in one window section
Noverlap = 2^13;        % Number of points of the overlap
Nfft = 2^14;            % Number of points in one bin
SpecType = 'PSD';       % 'PSD' or 'power'


p_ref = 20e-6;
[RMP_Gpp, f] = pwelch(p_mic,hanning(Nwindow),Noverlap,Nfft,f_s,SpecType);
RMP_PSD  = 10*log10(RMP_Gpp/p_ref^2);

