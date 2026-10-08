function [u] = WT_Start_Up
%WT_Start_Up
% This function initiates the connection with the wind tunnel over a TCP/IP  
% Returns the object - u - containing the connection information
% This function calls 2 sub fuctions:
%   [u] = WT_connect_v1(IP_add,Port_num)
%   All_Motors_ON_OFF(u, 1)
% It connects to the CX1000 and enables the servo drives
%   
%   INPUTS:
%       none
%
%   OUTPUTS:
%       u - username
%
% ---------------------------------------------------------------------
% Created by: Ronald Hanson - 07/21/2010
% Modifications:
% ---------------------------------------------------------------------
% Main Code

IP_add = '192.168.1.125';
Port_num = 23;

disp('Establish TCP/IP connection to the wind tunnel @ 192.168.1.125');

% The function [u] = WT_connect_v1(IP_add,Port_num) contains the parameters
% necessary to get the communication active
[u] = WT_connect_v1(IP_add,Port_num);
pause(2);

% All_Motors_ON_OFF(u, 1) will 
disp('*');
%disp('Enable Servo Drives');
%All_Motors_ON_OFF(u, 1)
pause(1);
fprintf(u,'Q');
pause(1)
fprintf(u,'W');
pause(1)
fprintf(u,'E');

%fprintf(u,'30');
 
