function [U,u_fluc] = SignalDecomp(u)
%SIGNALDECOMP breaks a signal into its mean and fluctuating
% components
%   INPUTS:
%       u - signal
%
%   OUTPUTS: 
%       U - mean of signal
%       u_fluc - fluctuating signal 
%
%   HISTORY:
%       Created - Daniel MacGregor (2021-11-13)
%
% -------------------------------------------------------------------------%   

U = mean(u);
u_fluc = u - U;
end

