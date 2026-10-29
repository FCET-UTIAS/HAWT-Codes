function [done] = MC_quit(s_port)
 
%---------------------------------------------------------------------------
% Function to release the motor control and close communication
% Description: Sends the release commands to the motor control box (bits
% 7 and 0, then 'Q' to quit), waits, then closes and deletes the serial
% port. The s_port object is invalid after this call, so open a new one
% with MC_open_traverse_talk to continue.
%
% INPUTS: s_port - serial port that the motor control box is connected to
% OUTPUTS: done  - returns 1 when the port has been closed and deleted
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

% Release motor contol and quit talking
    %fprintf(s_port, '/B 7')
    fprintf(s_port, '/B 7')
    fprintf(s_port, 'B 7')
    fprintf(s_port, 'B 0')
    fprintf(s_port, '0')
    fprintf(s_port, 'Q')
    % Clear the serial port
    pause(0.5);
    fclose(s_port);
    pause(0.5);
    delete(s_port);
    clear s_port
    done = 1;
end
