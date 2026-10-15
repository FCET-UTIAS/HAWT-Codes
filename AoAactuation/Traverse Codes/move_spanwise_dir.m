function move_spanwise_dir(distance_in_mm, direction, verbose)


if upper(string(direction)) == "UP"
    sign = '-';
elseif upper(string(direction)) == "DOWN"
    sign = '+';
end

steps = distance_in_mm*800;
if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk; %('COM4');  % Use COM8 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 1, 1);  

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit;

disp(' ');
disp('Traverse movement completed');
