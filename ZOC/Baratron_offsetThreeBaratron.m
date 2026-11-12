
function v_fs_offset = Baratron_offsetThreeBaratron(f_s,time)

disp('BEGIN Pressure Transducer Offset ----------------------------------')
disp('  Turn the knob on the baratron to 0? Press Enter after you are done...')
pause;
[~,PT_data] = Meas_T_PS_ThreeBaratron(f_s,time);
v_fs_offset = mean(PT_data);
tic;
disp(['    Initial offset voltage for Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
disp('END Pressure Trasnsducer Offset -----------------------------------')
disp('-------------------------------------------------------------------')
disp('  Turn back the knob on the baratron to 1? Press Enter after you are done...')
disp('   Tubes replaced? Press Enter to continue...')
pause;