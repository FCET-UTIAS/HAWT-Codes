close all
clear
clc
format long

%% Calculate turbulence intensity in the test section......................

cd ../../Raw-Data
load('1079.mat')
cd ../Codes/Codes
close all

%Vinf_mps_series = SW_data2vel(data_f(:,8), CALIB_SW, 'king');
[~, ~, ~, Vinf_mps_series] = get_pt_v(data_f(:,7), P_offset_v_u, 2*133.33, rho_kgpm3);   
Vinf_mps_mean   = mean(Vinf_mps_series);
Vprime_mps      = Vinf_mps_series - Vinf_mps_mean;

sum = 0;
for i = 1:length(Vprime_mps)
    
    sum = sum + Vprime_mps(i)^2;
    
end

Vprime_mps_squaresum = sum;

Vrms_mps = sqrt(Vprime_mps_squaresum/length(Vprime_mps));

Tupercent = Vrms_mps * 100 / Vinf_mps_mean
