function ZOCconfig = funcZOCconfigurationDefinition(config, xlsxFile)

%---------------------------------------------------------------------------
% Function to build the ZOC tap configuration from an Excel file
% Description: Reads the sheet named after the requested configuration and
% builds one group per unique GROUP# value, in order of first appearance.
% The number of groups, taps per group, and the modules used are all taken
% from the Excel file, so groups can be added or removed without editing
% this function. Several groups may share one ZOC module. Each tap row gives
% its channel-tap mapping in the MODULE and CHANNEL columns (e.g. MODULE
% 273, CHANNEL 25 = channel 25 of module 273). The ZOC scan returns the
% modules stacked in the order of ModuleOrder below (270, 273, 275, 32 channels
% each), so PortID = channel + 32*(module index - 1). Row order within a
% group is the tap number of that group.
%
% EXCEL FORMAT: sheet name = config ("Standard", "Glaze-Probed", ...)
%   Cell A1 "CHORD_MM", B1 chord length (mm). Header row on row 3, data
%   from row 4. Headers (any order, found by name):
%   GROUP#, X, Y, Z, DESCRIPTION, MODULE, CHANNEL
%   MODULE (270, 273 or 275) and CHANNEL (1-32) are plain numbers. GROUP#
%   may be left blank under the first row of a group (fill down).
%   X, Y, Z in mm. DESCRIPTION is stored per group (first non-empty entry).
%
% INPUTS: config   - sheet name / configuration, string
%         xlsxFile - (optional) Excel file, default
%                    'Pressure tap locations_SO.xlsx'
% OUTPUTS: ZOCconfig.GroupNames  - cell array of group names (in file order)
%          ZOCconfig.TotalVec    - number of taps in each group
%          ZOCconfig.ChordMM     - chord length (mm)
%          ZOCconfig.<group>.PortID, .x_mm, .y_mm, .z_mm, .x_c,
%                            .Module, .Channel, .Description
%          Group names are made valid field names (e.g. "1" -> "G1").
%
% HISTORY:
%   Author: Satoshi Baba, 2023 May
%   Modified: 2024 February to accomodate V3 pressure taps
%   Modified: 2026-05 SO Campaign
%   Rewritten: made dynamic; groups, taps and modules come from Excel.
%   Modified: November 2026 - MODULE and CHANNEL are now separate numeric columns.
%   NOT yet run in MATLAB.
%---------------------------------------------------------------------------

if nargin < 2
    xlsxFile = 'Pressure tap locations_SO.xlsx';
end

ModuleOrder = [270 273 275];   % order the modules are stacked in p_mean_Pa_temp
nChan = 32;

% Chord length
chord = readmatrix(xlsxFile, 'Sheet', char(config), 'Range', 'B1');

% Tap table found by header names
T = readtable(xlsxFile, 'Sheet', char(config), 'Range', 'A3', ...
    'VariableNamingRule', 'preserve', 'TextType', 'string');
names = string(T.Properties.VariableNames);
need = ["GROUP#" "X" "Y" "Z" "DESCRIPTION" "MODULE" "CHANNEL"];
for k = 1:numel(need)
    if ~any(upper(names) == need(k))
        error('funcZOCconfigurationDefinition:header', ...
            'Column "%s" not found in sheet "%s".', need(k), config);
    end
end
col = @(h) T.(names(upper(names) == h));

grp  = string(col("GROUP#"));
X    = double(col("X"));  Y = double(col("Y"));  Z = double(col("Z"));
desc = string(col("DESCRIPTION"));
modNum_all = double(col("MODULE"));  chNum_all = double(col("CHANNEL"));

% A blank GROUP# cell under a group name belongs to that group (fill down),
% so repeating the name on every row is optional. Rows with no MODULE number
% are treated as empty and dropped.
for n = 2:numel(grp)
    if (ismissing(grp(n)) || grp(n) == "") && ~isnan(modNum_all(n))
        grp(n) = grp(n-1);
    end
end
keep = ~ismissing(grp) & grp ~= "" & ~isnan(modNum_all);
grp = grp(keep); X = X(keep); Y = Y(keep); Z = Z(keep);
desc = desc(keep); modNum_all = modNum_all(keep); chNum_all = chNum_all(keep);

ZOCconfig.ChordMM = chord;
[groups, ~] = unique(grp, 'stable');
ZOCconfig.GroupNames = cell(1, numel(groups));
ZOCconfig.TotalVec = zeros(1, numel(groups));

for g = 1:numel(groups)
    idx = find(grp == groups(g));
    fname = matlab.lang.makeValidName(char(groups(g)), 'Prefix', 'G');

    % Module and channel of each tap in this group (row order = tap number)
    modNum = modNum_all(idx);  chNum = chNum_all(idx);
    if any(isnan(chNum))
        error('funcZOCconfigurationDefinition:channel', ...
            'Group %s has a tap with a MODULE but no CHANNEL number.', groups(g));
    end
    mIdx = arrayfun(@(m) find(ModuleOrder == m, 1), modNum, 'UniformOutput', false);
    if any(cellfun(@isempty, mIdx)) || any(chNum < 1 | chNum > nChan)
        error('funcZOCconfigurationDefinition:module', ...
            'Group %s has a module not in [%s] or a channel outside 1-%d.', ...
            groups(g), num2str(ModuleOrder), nChan);
    end
    mIdx = cell2mat(mIdx);

    d = desc(idx);  d = d(~ismissing(d) & d ~= "");
    ZOCconfig.(fname).PortID = (chNum + nChan*(mIdx-1)).';
    ZOCconfig.(fname).PortID = ZOCconfig.(fname).PortID(:);
    ZOCconfig.(fname).x_mm = X(idx);
    ZOCconfig.(fname).y_mm = Y(idx);
    ZOCconfig.(fname).z_mm = Z(idx);
    ZOCconfig.(fname).x_c  = X(idx)/chord;
    ZOCconfig.(fname).Module = modNum;
    ZOCconfig.(fname).Channel = chNum;
    if isempty(d), ZOCconfig.(fname).Description = ""; else, ZOCconfig.(fname).Description = d(1); end

    ZOCconfig.GroupNames{g} = fname;
    ZOCconfig.TotalVec(g) = numel(idx);
end

% A port used twice is almost certainly a typo in the Excel file
allPorts = cell2mat(cellfun(@(f) ZOCconfig.(f).PortID, ZOCconfig.GroupNames(:), 'UniformOutput', false));
if numel(unique(allPorts)) ~= numel(allPorts)
    warning('funcZOCconfigurationDefinition:duplicatePort', ...
        'The same ZOC port appears more than once in sheet "%s".', config);
end
end
