function ZOC_setup_data = ZOC_init_setup

ZOC_list = {'M270','M276','M275','M267','M273','091','092','093','094'};
[indx,~] = listdlg('PromptString',{'Which ZOC modules are you', 'using?'...
    'Control + click to select multiple options.',''},'ListString',ZOC_list);
ZOC_setup_data.serialnums = ZOC_list(indx);

analog_channel_prompt  = cell(length(indx)+1,1);
analog_channel_prompt{1} = 'DAQ device name';
for i = 2:length(indx)+1
    %analog_channel_prompt(i) = strcat('Analog channel for reading from module ','_',ZOC_setup_data.serialnums(indx(i-1)));
    analog_channel_prompt(i) = strcat('Analog channel for reading from module ','_',ZOC_setup_data.serialnums(i-1));
end

dims = [1 75].*ones(length(indx)+1,2);
ZOC_setup_data.analog_setup = inputdlg(analog_channel_prompt,'Analog Channels Setup for ZOCs (enter numbers only)', dims); 

ZOC_setup_data.terminal_config = {'Differential','SingleEnded','SingleEndedNonReferenced','PseudoDifferential'};
ZOC_setup_data.coupling = {'AC','DC','Default'};

[ZOC_setup_data.indx_config,~] = listdlg('PromptString',{'Select terminal configuration for analog channels.',...
    'Only one option can be selected at a time.',''},...
    'SelectionMode','single','ListString',ZOC_setup_data.terminal_config);

[ZOC_setup_data.indx_coupling,~] = listdlg('PromptString',{'Select coupling for analog channels.',...
    'Only one option can be selected at a time.',''},...
    'SelectionMode','single','ListString',ZOC_setup_data.coupling);
 
dims_2 = [1 100].*ones(12,2);

ZOC_setup_data.digital_setup = inputdlg({'Digital channel for writing to A0','Digital channel for writing to A1',...
            'Digital channel for writing to A2','Digital channel for writing to A3','Digital channel for writing to A4',...
            'Digital channel for writing to A5','Digital channel for reading from A0','Digital channel for reading from A1',...
            'Digital channel for reading from A2','Digital channel for reading from A3','Digital channel for reading from A4',...
            'Digital channel for reading from A5'},...
            'Digital Channels Setup for ZOCs (enter in the format PortX/LineY)', dims_2); 



