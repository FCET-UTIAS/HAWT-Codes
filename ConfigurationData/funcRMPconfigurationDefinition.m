function RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig)

%% Initialize
% The code requires all the tap groups from A to F to be defined, even if
% they are empty.
    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[]; % Up to 22
    RMP_DAQ_ID.C.tapID=[]; % Up to 24
    RMP_DAQ_ID.D.tapID=[]; % Up to 24
    RMP_DAQ_ID.E.tapID=[]; % Up to 19
    RMP_DAQ_ID.F.tapID=[]; % Up to 17
    RMP_DAQ_ID.G.tapID=[]; % Up to 17
    RMP_DAQ_ID.H.tapID=[]; % Up to 17
    
    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=[];
    RMP_DAQ_ID.C.DAQname=[];
    RMP_DAQ_ID.D.DAQname=[];
    RMP_DAQ_ID.E.DAQname=[];
    RMP_DAQ_ID.F.DAQname=[];
    RMP_DAQ_ID.G.DAQname=[];
    RMP_DAQ_ID.H.DAQname=[];
    
    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[];
    RMP_DAQ_ID.C.DAQchannel=[];
    RMP_DAQ_ID.D.DAQchannel=[];
    RMP_DAQ_ID.E.DAQchannel=[];
    RMP_DAQ_ID.F.DAQchannel=[];
    RMP_DAQ_ID.G.DAQchannel=[];
    RMP_DAQ_ID.H.DAQchannel=[];
    
    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[];
    RMP_DAQ_ID.C.RMPname=[];
    RMP_DAQ_ID.D.RMPname=[];
    RMP_DAQ_ID.E.RMPname=[];
    RMP_DAQ_ID.F.RMPname=[];
    RMP_DAQ_ID.G.RMPname=[];
    RMP_DAQ_ID.H.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=[];
    RMP_DAQ_ID.C.MeasurementType=[];
    RMP_DAQ_ID.D.MeasurementType=[];
    RMP_DAQ_ID.E.MeasurementType=[];
    RMP_DAQ_ID.F.MeasurementType=[];
    RMP_DAQ_ID.G.MeasurementType=[];
    RMP_DAQ_ID.H.MeasurementType=[];
    
%% Define configurations
if strcmp(RMPconfig,'Clean')
    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[57 58 28 59 60]; % Up to 22
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot4","PXI1Slot4", "PXI1Slot4","PXI1Slot4","PXI1Slot4"];
    RMP_DAQ_ID.C.DAQname=[];

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[ 9 8 5 6 7 ];
    RMP_DAQ_ID.C.DAQchannel=[];

    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[15 24 20 14 18];
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage","Voltage","Voltage","Voltage","Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];

    elseif strcmp(RMPconfig,'Clean-ALL')

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[1 2 3 4 6 7 8 9 10 11 12]; %in terms of Ai#
    RMP_DAQ_ID.C.DAQchannel=[];
    [DAQ_IDtemp,I]=sort(RMP_DAQ_ID.B.DAQchannel);
    RMP_DAQ_ID.B.DAQchannel=DAQ_IDtemp;

    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[9 11 44 56 26 54 53 57 58 28 60]; % Up to 22
    RMP_DAQ_ID.B.tapID=RMP_DAQ_ID.B.tapID(I);
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2"];
    RMP_DAQ_ID.C.DAQname=[];


    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[1 11 7 9 18 20 24 26 21 14 8];
    RMP_DAQ_ID.B.RMPname=RMP_DAQ_ID.B.RMPname(I);
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];


    elseif strcmp(RMPconfig,'Clean-redo60')

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[12]; %in terms of Ai#
    RMP_DAQ_ID.C.DAQchannel=[];
    [DAQ_IDtemp,I]=sort(RMP_DAQ_ID.B.DAQchannel);
    RMP_DAQ_ID.B.DAQchannel=DAQ_IDtemp;

    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[60]; % Up to 22
    RMP_DAQ_ID.B.tapID=RMP_DAQ_ID.B.tapID(I);
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot2"];
    RMP_DAQ_ID.C.DAQname=[];


    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[8];
    RMP_DAQ_ID.B.RMPname=RMP_DAQ_ID.B.RMPname(I);
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];

 elseif strcmp(RMPconfig,'Glaze-ONLY')

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[5 13];
    RMP_DAQ_ID.C.DAQchannel=[];
    [DAQ_IDtemp,I]=sort(RMP_DAQ_ID.B.DAQchannel);
    RMP_DAQ_ID.B.DAQchannel=DAQ_IDtemp;

    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[61 69]; % Up to 22
    RMP_DAQ_ID.B.tapID=RMP_DAQ_ID.B.tapID(I);
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot2","PXI1Slot2"];
    RMP_DAQ_ID.C.DAQname=[];


    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[5 14];
    RMP_DAQ_ID.B.RMPname=RMP_DAQ_ID.B.RMPname(I);
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage","Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];

elseif strcmp(RMPconfig,'Glaze-ALL')

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[1 2 3 4 5 6 7 8 9 10 11 12 13];
    RMP_DAQ_ID.C.DAQchannel=[];
    [DAQ_IDtemp,I]=sort(RMP_DAQ_ID.B.DAQchannel);
    RMP_DAQ_ID.B.DAQchannel=DAQ_IDtemp;

    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[9 11 44 56 61 26 54 53 57 58 28 60 69]; % Up to 22
    RMP_DAQ_ID.B.tapID=RMP_DAQ_ID.B.tapID(I);
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2","PXI1Slot2"];
    RMP_DAQ_ID.C.DAQname=[];


    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[1 11 7 9 15 18 20 24 26 21 14 8 19];
    RMP_DAQ_ID.B.RMPname=RMP_DAQ_ID.B.RMPname(I);
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage","Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];


   elseif strcmp(RMPconfig,'HW_TE_SS')
    RMP_DAQ_ID.A.tapID=[]; % up to 24
    RMP_DAQ_ID.B.tapID=[26 25]; % Up to 22
    RMP_DAQ_ID.C.tapID=[]; % Up to 24

    RMP_DAQ_ID.A.DAQname=[];
    RMP_DAQ_ID.B.DAQname=["PXI1Slot2","PXI1Slot2"];
    RMP_DAQ_ID.C.DAQname=[];

    RMP_DAQ_ID.A.DAQchannel=[];
    RMP_DAQ_ID.B.DAQchannel=[3 4];
    RMP_DAQ_ID.C.DAQchannel=[];

    RMP_DAQ_ID.A.RMPname=[];
    RMP_DAQ_ID.B.RMPname=[26 14];
    RMP_DAQ_ID.C.RMPname=[];

    RMP_DAQ_ID.A.MeasurementType=[];
    RMP_DAQ_ID.B.MeasurementType=["Voltage","Voltage"];
    RMP_DAQ_ID.C.MeasurementType=[];


end

