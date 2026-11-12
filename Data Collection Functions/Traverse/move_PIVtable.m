function move_PIVtable(distance_in_mm, direction, verbose)

if upper(string(direction)) == "UPSTREAM"
    sign = '-';
elseif upper(string(direction)) == "DOWNSTREAM"
    sign = '+';
end

steps = distance_in_mm*4000; % 400 steps/mm * 10:1 gear ratio = 4000 steps/mm

if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk;  % Check COM port with each time connected 

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 2, 1);  

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit;


disp(' ');
disp('Traverse movement completed');

end