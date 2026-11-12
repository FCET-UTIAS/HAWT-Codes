function u = SW_data2vel(e, handle, type)

% This function converts a voltage to a velocity when passed a calibration
% handle to evaluate and a calibration type.

% INPUT VARIABLES:
%      e = input voltage signal from a single-wire
% handle = calibration handle (e.g. polyfit or spline handle)
%   type = type of calibration handle

% OUTPUT VARIABLES;
%      u = velocity calculated from voltage signal

% R. Jason Hearst
% September 18, 2011

% King's Law
if strcmp(type,'king')==1 || strcmp(type,'King')==1 || strcmp(type,'KING')==1
    u = ((e.^2 -handle(1))/handle(2)).^(1/handle(3));

% Spline
elseif strcmp(type,'spline')==1 || strcmp(type,'Spline')==1 || strcmp(type,'SPLINE')==1
    u = ppval(handle, e);

% Polynomial fit
elseif strcmp(type(1:4),'poly')==1 || strcmp(type(1:4),'Poly')==1 || strcmp(type(1:4),'POLY')==1
    u = polyval(handle, e);

% Wrong type inputted
else
    disp('WARNING: You have inputted an invalid TYPE value for the calibration.');
    disp('         No actions have been performed.');
end

% --- END OF CODE ---