function [u] = WT_connect_v1(IP_add,Port_num)
% WT_connect_v1
%   This functino establishes the connection to the CX 1000 modual via a
%   TCP/IP interface.  
%   The Username is: User
%   The Password is: 6
% 
%   INPUTS:
%       IP_add - IP address
%       Port_num - port number
%
%   OUTPUTS:
%       u - username
%
% Created by: Ronald Hanson - 07/21/2010
% Modifications:
% 
% ---------------------------------------------------------------------
%% Main Code
u = tcpip(IP_add, Port_num);
pause(0.1)
set(u, 'Terminator', 'CR')
pause(0.1)
set(u, 'Timeout', 10)
pause(0.1)
set(u, 'InputBufferSize', 16384);
pause(0.1)
set(u, 'OutputBufferSize', 16384);
pause(0.1)
fopen(u)
pause(0.1)
check_que = get(u, 'BytesAvailable');
pause(0.1)
info = get(u);

% Read the buffer and write to file
while (get(u, 'BytesAvailable') > 1) 
u.BytesAvailable;
pause(0.01);
DataReceived = fscanf(u);
if length(DataReceived)>2
DataReceived(end) = [];
DataReceived(1) = [];
end
pause(0.01);
clear DataRecieved
end 

% Send the USERNAME
fprintf(u,'User');
pause(0.2)
% Send the PASSWORD
fprintf(u,'6');
pause(0.2);
DataReceived = fscanf(u);
DataReceived = fscanf(u);

% Read the buffer
while (get(u, 'BytesAvailable') > 1) 
u.BytesAvailable;
pause(0.01);
DataReceived = fscanf(u);
if length(DataReceived)>2
DataReceived(end) = [];
DataReceived(1) = [];
end
pause(0.01);
disp(DataReceived)
clear DataRecieved
end


% Welcome to the Four-Axis Motion Controller
% Top Level Instructions For Use:
% ?: Display these instructions
% Exit: or Quit: Exit this session
% D: Read all current axis drive status and positions
% A: Read all current analog input values
% L : Modify-X Axis upper movement limit 
% X: Selects operations on the X-Axis
% Y: Selects operations on the Y-Axis
% R: Selects operations on the Rotation-Axis
% T: Selects operations on the Tilt-Axis
% W: Selects operations on the Fan Speed 
% E: Toggles command echo in this windows