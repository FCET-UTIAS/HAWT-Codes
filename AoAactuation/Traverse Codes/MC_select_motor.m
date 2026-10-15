function MC_select_motor(s_port, selection, On_Off)
% MC_select_motor
%   This function selects or unselect the motors required by the user. The 
%   following table defines the selections to be executed:
% Value of variable 'selection'
%       1 : Motor 1
%       2 : Motor 2
%       3 : Motor 3
%   
%   INPUTS: 
%       s_port - serial port for motor control box
%       selection - motor to control
%                       Value of variable 'selection'
%                           1 : Motor 1
%                           2 : Motor 2
%                           3 : Motor 3
%       On_Off - turn motor on (1) or off (0)
%
%   OUTPUTS:
%       none
%
% Modified from the example of Philippe Lavoie 25-05-2005, 
% by Ronald Hanson 01-15-09
%--------------------------------------------------------------------------
%% Main Code

fprintf(s_port, '/B 0') 

if selection==1
    %%% Select motor 1 %%%
    fprintf(s_port, '/b 2')
    fprintf(s_port, '/b 3')
    fprintf(s_port, '/b 4')
    fprintf(s_port, 'b 5')
    if On_Off == 1
        fprintf(s_port, '/b 1') % Select
    else
        fprintf(s_port, 'b 1')  % Unselect
    end
end

if selection==2
    %%% Select motor 2 %%%
    fprintf(s_port, 'b 2')
    fprintf(s_port, '/b 3')
    fprintf(s_port, '/b 4')
    fprintf(s_port, 'b 5')
    if On_Off == 1
        fprintf(s_port, '/b 1') % Select
    else
        fprintf(s_port, 'b 1')  % Unselect
    end
end

if selection==3
    %%% Select motor 3 %%%
    fprintf(s_port, '/b 2')
    fprintf(s_port, 'b 3')
    fprintf(s_port, '/b 4')
    fprintf(s_port, 'b 5')
    if On_Off == 1
        fprintf(s_port, '/b 1') % Select
    else
        fprintf(s_port, 'b 1')  % Unselect
    end
end

if selection==4
    %%% Select motor 4 %%%
    fprintf(s_port, 'b 2')
    fprintf(s_port, 'b 3')
    fprintf(s_port, '/b 4')
    fprintf(s_port, 'b 5')
    if On_Off == 1
        fprintf(s_port, '/b 1') % Select
    else
        fprintf(s_port, 'b 1')  % Unselect
    end
end
    
% Execute selection
fprintf(s_port, '/b 7')
fprintf(s_port, 'b 7')
    
    
fprintf(s_port, 'B 7')
fprintf(s_port, 'B 1')
fprintf(s_port, '/B 0')
