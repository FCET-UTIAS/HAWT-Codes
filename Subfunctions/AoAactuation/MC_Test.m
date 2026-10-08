% MC TEST
% Test MC motor if it is connected and functioning

steps_to_mm = 800;
inverse_motor_speed = 2.3/10;

s_port = MC_open_traverse_talk('COM1');

disp('Connected')

MC_select_motor(s_port,1,1);

disp('Motor Selected')

MC_move_stepper(s_port,1000,'-');

disp('Command Sent')

MC_quit;

disp('Program Completion')
