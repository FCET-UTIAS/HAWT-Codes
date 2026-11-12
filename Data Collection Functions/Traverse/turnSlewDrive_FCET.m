function turnSlewDrive_FCET(steps, sign, verbose)
%
% Moves the traverse
%
% INPUTS:
%   - steps: (int) Number of steps to move the traverse
%   - sign: (string) The direction to move the traverse; '+' or '-'
%   - verbose: (optional; boolean) Print progress messages to the command
%   window
% 
% 2025-01-26 Currently 4000 steps per mm with the laser table and 10x gear
% reduction. +ve is downstream, -ve is upstream
%
% Note: If you ran MC_OPEN_TRAVERSE_TALK and there is a subsequent error
% before MC_QUIT runs, then you have to run fclose(instrfind) or restart 
% Matlab. 
%
% -------------------------------------------------------------------------

% Check that there are three arguments into the function
narginchk(3, 3)
steps = round(steps);

s_port = MC_open_traverse_talk;%('COM4');

if verbose; disp('Motor connected'); end

MC_select_motor(s_port, 1, 1);

if verbose; disp('Motor selected'); end

% steps_per_degree = 1887.5; % You move 1887.5 steps to get 1 degree
% steps = deg*steps_per_degree; 

MC_move_slewdrive(s_port, steps, sign);

if verbose; disp('Command sent'); end

MC_quit;

if verbose; disp('Program completion'); end
