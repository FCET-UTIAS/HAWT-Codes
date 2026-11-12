function TwoTraverse_PitotRake(steps, sign, verbose)
% For the 1.3m traverse:
%   800 steps = 1 mm
%   "+" = inside; "-" = outside

if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk;  % Use COM8 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 3, 1);  % Bottom
MC_select_motor(s_port, 4, 1);  % Top

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit;

if verbose ~= 0; disp('Program completion'); end
