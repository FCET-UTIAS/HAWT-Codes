function v_fs_offset = Baratron_offsetTwoBaratron(f_s, time)
% Measures the offset of the two Baratron setup in the AWT
% -------------------------------------------------------------------------

disp('BEGIN pressure transducer offset ----------------------------------')
disp('  Turn the knob on the Baratron to 0. Press Enter after you are done.')
pause;  % Prompt the user for input
disp('Measuring offset...')
[~, PT_data] = Meas_T_PS_TwoBaratron(f_s, time);
v_fs_offset = mean(PT_data);

disp(['    Initial offset voltage for Baratron: ' num2str(v_fs_offset, '%10.5f') ' V']);
disp('END pressure trasnsducer offset -----------------------------------')
disp('  Turn back the knob on the Baratron to 1? Press Enter after you are done.')
disp('  Tubes replaced? Press Enter to continue.')
pause;  % Prompt the user for input