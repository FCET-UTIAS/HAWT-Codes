%%% ZOC_SETUPZOCS
% ZOC_SETUPZOCS creates a table of zocmodule class objects. These objects
% contain all info about specific zoc modules as referenced by serial
% number. The objects are read from the ZOC Database file. The class
% objects are defined by the ZOC Module file. 
% 
% Inputs:
%   SERIALNUMBERS: should be n serial numbers input as a cell array object
%   (E.g.: serialnums = {'091', '092', '093', '094'};) 
%
% Output: 
%   ZOCS: table of zoc objects corresponding to the number of serial
%   numbers provided (assuming that all the serial numbers are valid
%   options)
%
% Author: Reuben Haklander, Oct 2022, Flow Control and Experimental 
% Turbulence Laboratory, University of Toronto Institute for Aerospace 
% Studies
% Revision date (YY-MM-DD): 22-10-21 

%modified by: Sogand Okhovatian - May 2026 
%modifications: efficiency enhancement for loading data
% -------------------------------------------------------------------------

function zocs = zoc_setupzocs_NRC(serialnumbers)
    zocs = table();
    zoctable = load("ZOC_Database", 'zocs').zocs; 
    for j = 1:width(serialnumbers)
        serial = serialnumbers{j}; 
            
            check = 0; 
                for i = 1:width(zoctable)
                    if serial == string(zoctable.(i).serialnumber)
                        zocs.(j) = zoctable.(i); 
                        check = 1;
                    else
                        continue 
                    end
                end
        
            if not(check)
                disp("Invalid serial number "+serial); 
            end
            zocs.(j) = update(zocs.(j), serial); 
        
            if string(class(zocs.(j))) == "ZOCModule"
                disp("Successfully loaded data for ZOC " + zocs.(j).serialnumber)
            else
                continue
            end
    end
    zocs.Properties.VariableNames = serialnumbers;
end
