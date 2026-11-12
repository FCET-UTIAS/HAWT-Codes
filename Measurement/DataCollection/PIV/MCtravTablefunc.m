%% function MCtravfunc(dist,dir,motorNum)

% input:
% - dist: distance to be travelled (mm). The pitch of the lead screw is 
%         assumed to be 1 mm per rotation
% - dir: direction. '+' or '-'
% - motorNum: the motor controller channel number. 1 to 4.

function MCtravTablefunc(dist,dir,motorNum)
travstepangle=1.8/4; % deg/pulse, spec sheet
travscrewpitch=2/360; %mm/deg
travRes=travstepangle*travscrewpitch;

stepNum=dist/travRes;

s_port = MC_open_traverse_talk('COM3');

%disp('Connected')

MC_select_motor(s_port,motorNum,1);

%disp('Motor Selected')
  
MC_move_stepper(s_port,stepNum,dir);
% dir: '+', '-'

%disp('Command Sent')

MC_quit;

disp('Program Completion')
end
