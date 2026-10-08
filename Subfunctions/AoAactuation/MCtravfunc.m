function MCtravfunc(dist,dir,gain)
% MC TEST
% Test MC motor if it is connected and functioning

if dist<0
    error
elseif dist>200
    error
end


% pause(10);
travstepangle=1.8/4; % deg/pulse, spec sheet
travscrewpitch=2/360; %mm/deg
travRes=travstepangle*travscrewpitch;

motorNum=2;

stepNum=dist/travRes*gain;

s_port = MC_open_traverse_talk('COM3');

disp('Connected')

MC_select_motor(s_port,motorNum,1);

disp('Motor Selected')
  
MC_move_stepper(s_port,stepNum,dir);
% dir: '+', '-'

disp('Command Sent')

MC_quit;

disp('Program Completion')
end
