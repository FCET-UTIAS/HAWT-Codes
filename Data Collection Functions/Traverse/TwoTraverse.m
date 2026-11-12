function stepsfromhome = TwoTraverse(steps, sign, verbose, stepsfromhome)
% For the 1.3m traverse:
%   800 steps = 1 mm
%   "+" = inside; "-" = outside

if exist('verbose') == 0
    verbose = 0;
end

if exist('stepsfromhome') == 0
    stepsfromhome = 0; 
end


s_port = MC_open_traverse_talk;  % Use COM4 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 3, 1);  % Bottom
MC_select_motor(s_port, 2, 1);  % Top

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if sign == '+'
    stepsfromhome = stepsfromhome + steps; 
else
    stepsfromhome = stepsfromhome - steps; 
end

if verbose ~= 0; disp('Command sent'); end

MC_quit;

if verbose ~= 0; disp('Program completion'); end
