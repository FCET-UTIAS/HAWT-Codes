


function [rawData, VoltMean, VoltStd]=SupercriticalZOCmeas(f_s,t_s)
[rawDataTemp, VoltMeanTemp, VoltStdTemp] = ZOC_serial_scan(f_s,t_s);
rawData=cat(2,squeeze(rawDataTemp(:,1,:)),squeeze(rawDataTemp(:,2,:)),squeeze(rawDataTemp(:,3,:)),squeeze(rawDataTemp(:,4,:)));
VoltMean=[squeeze(VoltMeanTemp(1,:)),squeeze(VoltMeanTemp(2,:)),squeeze(VoltMeanTemp(3,:)),squeeze(VoltMeanTemp(4,:))];
VoltStd=[squeeze(VoltStdTemp(1,:)),squeeze(VoltStdTemp(2,:)),squeeze(VoltStdTemp(3,:)),squeeze(VoltStdTemp(4,:))];
end