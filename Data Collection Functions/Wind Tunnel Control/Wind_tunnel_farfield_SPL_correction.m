function [total_correction, SPL_corrected] = Wind_tunnel_SPL_correction(U_inf,F,SPL)
%inputs :
%U_inf = Flow velcoity in m/s must be 40,50 or 60
%SPL = SPL at each frequency to be corrected in db or db/Hz
%Outputs : 
% total correction
% corrected SPL


a_40 = 1.0796;
b_40 = 6.17;
c_40 = 0.0019;
a_50 = 1.3783;
b_50 = 5.764;
c_50 = 0.0117
a_60 = 1.8505;
b_60 = 3.4970;
c_60 = 0.0011;

for i = 1:length(F)
    if U_inf == 40
        a = a_40;
        b = b_40;
        c = c_40;
    elseif U_inf == 50
        a = a_50;
        b = b_50;
        c= c_50;
    elseif U_inf == 60
        a = a_60;
        b = b_60;
        c= c_60;
    end
Bl_attenuate = a-b*exp(-c*F(i));
Kevlar_attenuate = 8.93e-3*(F(i)/1000)^2;

total_correction(i) = Bl_attenuate+Kevlar_attenuate;
SPL_corrected = SPL - total_correction; 
end
end