function [slat, main, flap, main_span, flap_span] = import_P_tap_points_2015(d)

datFiles = dir(d);
N = length(datFiles); 

% loop for each file 
 P_taps = cell(N-2,1);

for i = 3:N
   thisFile = datFiles(i).name ; 
   filename = fullfile(d,thisFile);
   data = importdata(filename);
   P_taps{i-2} = data;
end

clear data

slat = P_taps{5};
main = P_taps{4};
flap = P_taps{2};
flap_span = P_taps{1};
main_span = P_taps{3};
