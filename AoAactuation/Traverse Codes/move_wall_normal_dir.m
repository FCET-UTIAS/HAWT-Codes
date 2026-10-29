function move_wall_normal_dir(distance_in_mm, direction, verbose)
% For the 1.3m traverse:
%   800 steps = 1 mm
%   "+" = inside; "-" = outside

if upper(string(direction)) == "AWAY"
    sign = '+';
elseif upper(string(direction)) == "TOWARDS"
    sign = '-';
end
steps = distance_in_mm*800;
if exist('verbose') == 0
    verbose = 0;
end
    
s_port = MC_open_traverse_talk; %('COM4');  % Use COM8 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 2, 1);  % Bottom
MC_select_motor(s_port, 3, 1);  % Top

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end


MC_quit(s_port);

disp(' ');
disp('Traverse movement completed');
