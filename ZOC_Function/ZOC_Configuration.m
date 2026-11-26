function ZOCconfig = funcZOCconfigurationDefinition(config, xlsxFile)

%---------------------------------------------------------------------------
% Function to build the ZOC tap configuration from an Excel file
% Description: Reads the sheet named after the requested configuration and
% builds one group per unique GROUP# value, in order of first appearance.
% The number of groups, taps per group, and the modules used are all taken
% from the Excel file, so groups can be added or removed without editing
% this function. Several groups may share one ZOC module. Each tap row gives
% its channel-tap mapping in the MODULE column as "module:channel" (e.g.
% 273:25 = channel 25 of module 273). The ZOC scan returns the modules
% stacked in the order of ModuleOrder below (270, 273, 275, 32 channels
% each), so PortID = channel + 32*(module index - 1). Row order within a
% group is the tap number of that group.
%
% EXCEL FORMAT: sheet name = config ("Standard", "Glaze-Probed", ...)
%   Cell A1 "CHORD_MM", B1 chord length (mm). Header row on row 3, data
%   from row 4. Headers (any order, found by name):
%   GROUP#, X, Y, Z, DESCRIPTION, MODULE
%   Separator in MODULE can be : - or _ (format the column as Text in Excel
%   so 273:25 is not turned into a time). GROUP# may be left blank under the
%   first row of a group (fill down). X, Y, Z in mm. DESCRIPTION is stored per group (first non-empty entry).
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
need = ["GROUP#" "X" "Y" "Z" "DESCRIPTION" "MODULE"];
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
mod  = string(col("MODULE"));

% A blank GROUP# cell under a group name belongs to that group (fill down),
% so repeating the name on every row is optional. Rows with no MODULE entry
% are treated as empty and dropped.
for n = 2:numel(grp)
    if (ismissing(grp(n)) || grp(n) == "") && ~(ismissing(mod(n)) || mod(n) == "")
        grp(n) = grp(n-1);
    end
end
keep = ~ismissing(grp) & grp ~= "" & ~ismissing(mod) & mod ~= "";
grp = grp(keep); X = X(keep); Y = Y(keep); Z = Z(keep);
desc = desc(keep); mod = mod(keep);

ZOCconfig.ChordMM = chord;
[groups, ~] = unique(grp, 'stable');
ZOCconfig.GroupNames = cell(1, numel(groups));
ZOCconfig.TotalVec = zeros(1, numel(groups));

for g = 1:numel(groups)
    idx = find(grp == groups(g));
    fname = matlab.lang.makeValidName(char(groups(g)), 'Prefix', 'G');

    % Parse "module:channel"
    modNum = zeros(numel(idx),1);  chNum = zeros(numel(idx),1);
    for n = 1:numel(idx)
        parts = string(regexp(strtrim(char(mod(idx(n)))), '[:\-_]', 'split')); % accepts 273:25, 273-25, 273_25
        if numel(parts) ~= 2 || any(isnan(double(parts)))
            error('funcZOCconfigurationDefinition:module', ...
                'Group %s tap %d: MODULE "%s" is not of the form module:channel.', ...
                groups(g), n, mod(idx(n)));
        end
        modNum(n) = double(parts(1));  chNum(n) = double(parts(2));
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
