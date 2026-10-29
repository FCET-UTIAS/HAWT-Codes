%% ZOCPortID=funcZOCconfigurationDefinition(TapGroup,TapNum)
% Returns the ZOC pressure port number based on the surface pressure tap
% location input

% input:
% - TapGroup: The surface pressure tap group. eg. A, B, C, ...
% - TapNum: The tap number of each of the group. If you want the entire
%           TapGroup, input -1

% output:
% - ZOCportID: The ZOC port number that corresponds to the user defined
%              surface pressure port.

% eg. If you want the ZOC port number of the surface tap A2, A3, A5, B2 and 
% the whole C,then the input will be TapGroup=['A','A','A','B','C'], 
% TapNum=[2 3 5 2 -1]. The output will be [2 3 5 26 47 48 49 50 ... 70].

% Author: Satoshi Baba, 2023 May
% Modified: 2024 February to accomodate V3 pressure taps
% Modified: 2026-05 SO Campaign

%function [TotalPortID,ZOCportNum]=funcZOCconfigurationDefinition(TapGroup,TapNum)
function ZOCconfig=funcZOCconfigurationDefinition(config)
if strcmp(config,"Standard")
    ZOCconfig.TotalVec=[24 22 23];
    
    ZOCconfig.A.PortID=[25, (2:24)] + 32; %module 273 - second channel input
    ZOCconfig.B.PortID=(1:22)+64; %module 275 - third channel input
    ZOCconfig.C.PortID=[(1:7), 29, (10:11), (13:17), (19:25),32]; %module 270 - first channel input
    
    ZOCconfig.A.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','A15:A38'));
    ZOCconfig.B.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','C16:C20'));
    ZOCconfig.C.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','E15:E37'));
   
    ZOCconfig.A.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','B15:B38'));
    ZOCconfig.B.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','D16:D20'));
    ZOCconfig.C.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup', 'Range','F15:F37'));

elseif strcmp(config,"Glaze-Probed")
    ZOCconfig.TotalVec=[24 22 23];
    
    ZOCconfig.A.PortID=[25, (2:24)] + 32; %module 273 - second channel input
    ZOCconfig.B.PortID=[(1:5), (23:31)]+64; %module 275 - third channel input (1-5 for TE (midspan, channels 23-31 for Glaze)
    ZOCconfig.C.PortID=[(1:7), 29, (10:11), (13:17), (19:25),32]; %module 270 - first channel input
    
    ZOCconfig.A.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','A15:A38'));
    ZOCconfig.B.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','C16:C29'));
    ZOCconfig.C.x_mm=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','E15:E37'));
   
    ZOCconfig.A.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','B15:B38'));
    ZOCconfig.B.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','D16:D29'));
    ZOCconfig.C.x_c=table2array(readtable('Pressure tap locations_SO.xlsx','Sheet', 'ZOC_setup_Glaze', 'Range','F15:F37'));
end

end