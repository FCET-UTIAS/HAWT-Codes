%% Modified by SO - May 11th
%modification: line 81 to include calibration file path/folder

%% Database for ZOC Module info

%Data is contained for each ZOC module and is retrieved by serial number

serialnums = {'M270', 'M276', 'M275', 'M267', 'M273'};
modelname = {'ZOC 22B', 'ZOC 22B', 'ZOC 22B', 'ZOC 22B', 'ZOC 22B'};

% Transducer Range
sensorrange = [5, 5, 5, 5, 2.5]; %NOTE: DOUBLE CHECK THESE VALUES

% Tranducer Banks
sensorbanks = [1, 1, 1, 1, 1]; 

%% Working transducers for each serial number

sensorgood_M270 = [1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1]; 
sensorgood_M276 = [1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1]; 
sensorgood_M275 = [1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1]; 
sensorgood_M267 = [1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1]; 
sensorgood_M273 = [0	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1]; 

sensorgood = {sensorgood_M270, sensorgood_M276, sensorgood_M275, sensorgood_M267, sensorgood_M273}; 

sensornumber = [length(sensorgood_M270), length(sensorgood_M276), length(sensorgood_M275), length(sensorgood_M267), length(sensorgood_M273)]; 

%% Transducer Calibration
calibrationfiles = ["M270_gain.mat"; 
    "M276_gain.mat";
    "M275_gain.mat";
    "M267_gain.mat";
    "M273_gain.mat"]; 

%Note: commented out is no longer run, saved for reference for input checking logic
% % Choosing ZOC Module to calibrate
% while 1
%     cal_serial = input('Which ZOC Module would you like to re-load calibration? (E.g. 190) ("n" to skip): ', "s");
%     check = 0; 
%     for j = 1:width(serialnums)
%         if cal_serial == string(serialnums{j})
%             module = j; 
%             check = 1; 
%             break
%         elseif upper(cal_serial) == "N"
%             check = 2; 
%             break
%         else
%             continue
%         end
%     end
%     if ~check
%         disp('Please input a valid serial number'); 
%         continue
%     elseif check == 2
%         break
%     end
%     break
% end
% %User input for file name, load calibration from file
% while 1
% foldername = input('Please input the FOLDER name or path that contains calibration file (E.g. ZOCCalibration__220725_151441__serialno-190): ', "s"); 
% level = wildcardPattern + "\";
% pat = asManyOfPattern(level); 
% tempfilename = string(extractAfter(foldername,pat)); 
% filename = foldername+"\"+tempfilename+"_ASCII";
% try
%     sensorcal = load(filename, "-ascii");
%     break
% catch
%     disp('Folder does not contain ASCII file, please try again'); 
%     continue
% end
% end

%Loading ZOC calibrations from file
zoccalib = {}; 
for i = 1:length(calibrationfiles)
    try
        sensorcal = load(fullfile('NRC_ZOCs_Cal_files', 'CAL_files_gains_only',calibrationfiles(i)));
        zoccalib{i} = sensorcal;
        continue
    catch
        zoccalib{i} = zeros(2,(sensorbanks(i)*sensornumber(i)));
        continue
    end    
end

%% Updating Database sets
zocs = table(); 
for i = 1:length(serialnums)
    zocs.(i) = ZOCModule(serialnums{i}, modelname{i}, sensorrange(i), sensorbanks(i), sensornumber(i), eval(strcat('zoccalib{i}.',serialnums{i},'_gain')));
end
zocs.Properties.VariableNames = serialnums;
save("ZOC_Database", "zocs"); 