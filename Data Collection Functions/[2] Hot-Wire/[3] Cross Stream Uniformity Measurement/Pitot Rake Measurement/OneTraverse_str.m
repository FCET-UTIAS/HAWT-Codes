function OneTraverse_str(steps, sign, verbose)
% Moves the traverse
%
% INPUTS:
%   - steps: (int) Number of steps to move the traverse
%   - sign: (string) The direction to move the traverse; '+' or '-'
%   - verbose: (optional; boolean) Print progress messages to the command
%   window
% 
% -------------------------------------------------------------------------
if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk;

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 1, 1);

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit;

if verbose ~= 0; disp('Program completion'); end
