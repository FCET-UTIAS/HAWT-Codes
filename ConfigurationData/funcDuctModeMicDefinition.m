function DuctModeMicID=funcDuctModeMicDefinition

    DuctModeMicID.mic1.location=[0 0 0];
    DuctModeMicID.mic2.location=[0 0.83/4 0];
    DuctModeMicID.mic3.location=[0.83/4 0.83/4 0];
    DuctModeMicID.mic4.location=[0 -0.83/4 0];
    DuctModeMicID.mic5.location=[-0.83/4 -0.83/4 0];
    DuctModeMicID.micRef.location="NaN";
    
    DuctModeMicID.DAQname=["PXI1slot2","PXI1slot2","PXI1slot2","PXI1slot2","PXI1slot2","PXI1slot2"];
    
    DuctModeMicID.DAQchannels.PXI1slot2=[0 1 2 3 4 5];
    
    DuctModeMicID.serialNum=["1","2","3","4","5","6"];



end