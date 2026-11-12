function [sRMP,TRMP,PxxBK,PxxMic]=funcRMPcalibrationProcessing()

% coherence function
[Cxy,F] = mscohere(BK, mic_rawdata, window,[],window/2,Fs);
% transfer function
[Txy,F] = tfestimate(BK,mic_rawdata,window,[],window/2,Fs);
% BK - power spectrum density
[Pxx_BK,F] = pwelch(BK,window,[],window/2,Fs);
% Mic. - power spectrum density
[Pxx_mic_rawdata,F] = pwelch(mic_rawdata,window,[],window/2,Fs);

figure;
semilogx(F, Cxy), title('Coherence'); xlim([0 20e3])
%legend('Meas mic GRAS','Meas mic PCB','Meas mic Knowles')
%legend('Meas mic PCB','Meas mic Knowles')
ylim([0 1])
grid on
box on
xlim([10 10000])

figure;
semilogx(F,20*log10(abs(Txy))), title('Transfer');
%legend('Meas mic GRAS','Meas mic PCB','Meas mic Knowles')
%legend('Meas mic PCB','Meas mic Knowles')
xlim([0 20e3])
grid on
box on

figure;
semilogx(F,((angle(Txy)))), title('Wrapped Phase');xlim([0 20e3])
%legend('Meas mic GRAS','Meas mic PCB','Meas mic Knowles')
%legend('Meas mic PCB','Meas mic Knowles')
grid on
box on

figure;
plot(F,(unwrap(angle(Txy)))), title('Phase');xlim([0 20e3])
%legend('Meas mic GRAS','Meas mic PCB','Meas mic Knowles')
%legend('Meas mic PCB','Meas mic Knowles')
grid on
box on
    
figure
semilogx(F,20*log10(sqrt(Pxx_BK)/20e-6),F,20*log10(sqrt(Pxx_mic_rawdata)/20e-6),'LineWidth',2), 
%legend('Ref','Meas mic GRAS','Meas mic PCB','Meas mic Knowles')
%legend('Ref','Meas mic PCB','Meas mic Knowles')
legend('Ref','Meas mic Knowles','Ref mic Knowles')
grid on
box on
xlim([0 20e3])
ylabel('SPL [dB]')
xlabel('Frequency [Hz]')

figure;
semilogx(F, Cxy(:,1)), title('Coherence'); xlim([0 20e3])
xlim([10 10000])
grid on
box on
%%
figure
subplot(2,1,1)
semilogx(F,20*log10(abs(Txy)))
xlim([10 10000])
title('experimental results')
xlabel('Frequency (Hz)')
ylabel('$20log_{10}|\textit{H}|$','interpreter','latex')

subplot(2,1,2)
semilogx(F,rad2deg(angle(Txy)))
xlim([10 10000])
title('experimental results')
xlabel('Frequency (Hz)')
ylabel('Phase','interpreter','latex')