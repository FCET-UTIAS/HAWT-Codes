function [done] = MC_quit(s_port)

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