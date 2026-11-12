function funcZOCconfigurationDefinition2(rawData)


% Defines which tap will be measured, which DAQ it corresponds to, 


% - Purpose: "AoAeffectiveCalibration", "MidSpan", "Tip", "All"

%{
    MicDAQ_ID.Position=["PressureSide1","PressureSide2","PressureSide3","PressureSide4","PressureSide5","PressureSide6","PressureSide7","SuctionSide1"];
    MicDAQ_ID.DAQname=["PXI1Slot3","PXI1Slot3","PXI1Slot3","PXI1Slot3","PXI1Slot3","PXI1Slot3","PXI1Slot3","PXI1Slot3"];
    MicDAQ_ID.DAQchannel=[1 2 3 4 5 6 7 8];
%}



struct CpChannelID
tapNumVec=[26 26 9 4 4];
Alphabet=["A","B","C","D","E"];




for groupID=1:length(tapNumVec)
    for tapID=1:tapNumVec(groupID)
        CpData.(Alphabet(groupID)).vRawData=rawData(CpData.A.ZOCport(tapID));
    end
end

    





end