%% Wind Tunnel Shut-down Code
%
% This program shuts down the wind tunnel and deletes the object.
% The script assumes that you are at the fan speed control level
%
% R. Jason Hearst
% September 16, 2011
%
%
%--------------------------------------------------------------------------
%% Main Code
% Shut-down commands to wind tunnel
fprintf(WT,'0');    % Set speed to 0
pause(5);
fprintf(WT,'D');    % Disable the VFD
pause(1);
fprintf(WT,'Q');    % Go to a higher level in the control
pause(1);
fprintf(WT,'Exit'); % Exit the WT controller
pause(1);

% Clean-up the object
fclose(WT);
delete(WT);
clear WT;