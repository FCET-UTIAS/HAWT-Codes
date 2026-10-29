%% function MicID=funcLinearMicArrayConfigDefinition
% The function defines DAQ channel setting for the linear microphone array.

% The function positions 7 microphones on the side of the suction surface 
% and 1 microphone on the side of the pressure surface.

function MicDAQ_ID=funcLinearMicArrayConfigDefinition
    MicDAQ_ID.serialNum=[ "477076","477080"]; %
    MicDAQ_ID.type=["GRAS", "GRAS"];
    MicDAQ_ID.model=["46BF-1", "46BF-1"];
    MicDAQ_ID.position=["SuctionSide1", "PressureSide1"];
    MicDAQ_ID.DAQname=["PXI1Slot2", "PXI1Slot2" ];
    MicDAQ_ID.MeasurementType=["Voltage", "Voltage" ];
    MicDAQ_ID.DAQchannels=[14 15];
    MicDAQ_ID.BNCcableNum=[15 16];
end