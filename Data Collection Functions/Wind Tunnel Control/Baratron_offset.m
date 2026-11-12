
function v_fs_offset = Baratron_offset(PT_f_s,PT_t_s)

disp('BEGIN Pressure Transducer Offset ----------------------------------')
disp('  Turn the knob on the baratron to 0? Press Enter after you are done...')
pause;
[~,V_Cp] = Meas_T_PS2(0, PT_f_s, PT_t_s, 0);
v_fs_offset = mean(V_Cp);
tic;
disp(['    Initial offset voltage for Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
disp('END Pressure Trasnsducer Offset -----------------------------------')
disp('-------------------------------------------------------------------')
disp('  Turn back the knob on the baratron to 1? Press Enter after you are done...')
disp('   Tubes replaced? Press Enter to continue...')
pause;