%constant parameters to calculate the frameLen
FFTLength            = 64;
CyclicPrefixLength   = 16;
NumOFDMSymInPreamble = 13;
NumBitsPerCharacter  = 7;
NumDataCarriers      = 23;
osf                  = 2;  % Oversampling factor
fs                   = 0.15625e6/osf; % Transmit sample rate in MHz

%message to be send : 
%1) converted first in char
msg = "test for a given string \n";
msg = char(msg);
%2) converted then in bits
msgInBits = coder.const(double(dec2bin(msg,NumBitsPerCharacter).')-48);

modulationType = 'QPSK';
modulationOrder = 2;
numFrames = 200;
% 
% release(sdrTransmitter); 
% release(sdrReceiver);

%the frame size can easily be changed by choosing the number of OFDM
%symbols to transmit the ayload data
[frame,nbBitFrame,numPayLoadBitInFrame] = prepareFrame(msgInBits,NumDataCarriers,modulationOrder);

header = coder.const(double(dec2bin(numPayLoadBitInFrame).')'-48);
NumBitInHeader = length(header(1,:));
           
%TRANSMITER% 
OFDMTX = OpticalOFDMTransmitter('SampleRate',fs,...
                                    'MsgInBits',frame',...
                                    'header',header,...  
                                    'ModulationType', modulationType );
                                

pPSDSA = dsp.SpectrumAnalyzer( ...
    'Name',      'Transmited Signal spectrum', ...
    'SampleRate',fs*osf);


[txSig,ofdmsig,FrameHeader,referenceComplexSig] = OFDMTX();
FrameLength = OFDMTX.FrameLength+80;
tabFrameLengthOFDMSig = length(ofdmsig);
tabFrameLengthheader = length(FrameHeader);
tabFrameLength = length(txSig);
frameLen = FrameLength;

%PLUTO RADIO%
%  Initialize SDR device
deviceNameSDR = 'Pluto'; % Set SDR Device
radio = sdrdev(deviceNameSDR);           % Create SDR device object


txGain = -10;

sdrTransmitter = sdrtx(deviceNameSDR); % Transmitter properties
sdrTransmitter.RadioID = 'usb:0';
sdrTransmitter.BasebandSampleRate = fs*osf;
sdrTransmitter.CenterFrequency = 5.5e8;  % Channel 
sdrTransmitter.ShowAdvancedProperties = true;
sdrTransmitter.Gain = txGain;


% Resample transmit waveform 
txSig  = resample(txSig,fs*osf,fs);

% Scale the normalized signal to avoid saturation of RF stages
powerScaleFactor = 0.8;
txSig = txSig.*(1/max(abs(txSig))*powerScaleFactor);

txSig = complex(txSig);

%pPSDSA(txSig); 


[results] = calculateParameters(fs,osf,frameLen,modulationOrder,FFTLength,numPayLoadBitInFrame);
% Transmit RF waveform
sdrTransmitter.transmitRepeat(txSig);

% % An <matlab:plutoradiodoc('commsdrrxpluto') SDR Receiver> System object is
% % used with the PlutoSDR to receive baseband data from the SDR hardware.
sdrReceiver = sdrrx(deviceNameSDR);
sdrReceiver.RadioID = 'usb:0';
samplesPerFrame = length(txSig);
sdrReceiver.SamplesPerFrame = samplesPerFrame*(numFrames+500);
sdrReceiver.BasebandSampleRate = sdrTransmitter.BasebandSampleRate;
sdrReceiver.CenterFrequency = sdrTransmitter.CenterFrequency;
sdrReceiver.GainSource = 'Manual';
sdrReceiver.Gain = 10;
sdrReceiver.OutputDataType = 'double';

rxSig = sdrReceiver(); 

rxSig = resample(rxSig,fs,fs*osf);
       

%RECEIVER%
showMsg = true;
showScopes = false;
ofdmrx = OpticalOFDMReceiver2( ...
        'SampleRate',fs,...
        'FrameLength',    frameLen, ...
        'DisplayMessage', showMsg,  ...
        'numFrames',numFrames,...
        'ModulationType', modulationType, ...
        'numBitHeader', NumBitInHeader, ...
        'referenceComplexSig', referenceComplexSig, ...
        'ShowScopes',     showScopes);

[decMsgInBits, numFramesDetected,payLoadBit,received_symbols] = ofdmrx(rxSig);

if numFramesDetected <= numFrames
    numFramesMeasur = numFramesDetected;
else
    numFramesMeasur = numFrames;
end

[FER, BER] = calculateOFDMBER(msg, decMsgInBits, numFramesMeasur);
EVR = Calculate_EVR(received_symbols,modulationType,referenceComplexSig,numFramesMeasur);

fprintf('\n %d fames detected  with FER = %f / BER = %f\n and EVR = %f \n', ...
     numFramesDetected, FER, BER,EVR); 

release(sdrTransmitter); 
release(sdrReceiver);

function EVR = Calculate_EVR(received_symbols,modulationType,referenceComplexSig,numFramesDetected)
    received_symbols = reshape(received_symbols,1,length(received_symbols(:)));
    referenceComplexSig = reshape(referenceComplexSig,1,length(referenceComplexSig(:)));
    referenceComplexSig = repmat(referenceComplexSig,1,numFramesDetected);
    
    switch modulationType 
        case 'BPSK'
            reference_constellation = complex([ -1.0000 + 0.0000i ,  1.0000 + 0.0000i]);
            N = 2;
        case 'QPSK'
            reference_constellation = complex([  -0.7071 + 0.7071i ,   0.7071 + 0.7071i ,   0.7071 - 0.7071i,  -0.7071 - 0.7071i]);
            N = 4;
        case 'QAM'
            reference_constellation = complex([  -3.00 + 3.00i ,   -1.00 + 3.00i ,  1.00 + 3.00i,  3.00 + 3.00i,...
                                        -3.00 + 1.00i ,   -1.00 + 1.00i ,  1.00 + 1.00i,  3.00 + 1.00i,...
                                        -3.00 - 1.00i ,   -1.00 - 1.00i ,  1.00 - 1.00i,  3.00 - 1.00i,...
                                        -3.00 - 3.00i ,   -1.00 - 3.00i ,  1.00 - 3.00i,  3.00 - 3.00i]);
            N = 16;
    end 
    
    A0 = sqrt(N/sum(real(reference_constellation).^2 + imag(reference_constellation).^2));
    A = sqrt(length(received_symbols(:))/sum(real(received_symbols).^2 + imag(received_symbols).^2));

    error = 1/length(received_symbols(:))*sum(abs(real(received_symbols).*A - real(referenceComplexSig).*A0).^2 + abs(imag(received_symbols).*A - imag(referenceComplexSig).*A0).^2);
    reference_power = 1/length(received_symbols(:))*sum(abs(real(referenceComplexSig).*A0).^2 + abs(imag(referenceComplexSig).*A0).^2);
    
    EVR = sqrt(error /reference_power);
    
end 

function [results] = calculateParameters(fs,osf,frameLen,modulationOrder,FFTLength,numPayloadBitInFrame)
    CpLength = 16;
    sample_time = 1/(fs*osf);
    bandwidth = 1/sample_time;
    subcarrier_spacing = bandwidth/(FFTLength+CpLength);
    sample_per_frame = frameLen* osf;
    %ofdm_symbol_per_frame = 5 + numPayLoadOFDMSymbols + 1;
    frame_time = sample_time * sample_per_frame;
    bit_per_frame = floor(frameLen/modulationOrder);
    bit_rate = bit_per_frame/frame_time;
    data_rate = numPayloadBitInFrame/frame_time;
    results = {'bandwidth',bandwidth;...
               'subcarrier_spacing',subcarrier_spacing;...
               'sample_time',sample_time;...
               'sample_per_frame',frameLen;...
               'bit_rate', bit_rate;...
               'data_rate',data_rate;...
               'frame_time',frame_time};
end

function [frame,nbBitInFrame,numPayloadBitInFrame] = prepareFrame(msgInBits,NumDataCarriers,modulationOrder)
    frameSize = 2000; %500 bytes
    
    if modulationOrder == 16
         numPayLoadOFDMSymbols = fix((frameSize)/(NumDataCarriers*log2(modulationOrder)));
         nbBitInFrame = NumDataCarriers*log2(modulationOrder)*numPayLoadOFDMSymbols;
    else
         numPayLoadOFDMSymbols = fix((frameSize)/(NumDataCarriers*modulationOrder));
         nbBitInFrame = NumDataCarriers*modulationOrder*numPayLoadOFDMSymbols;
    end 
    
    frame = (randi([0 1], nbBitInFrame, 1));
    numPayloadBitInFrame = zeros(1);
    if nbBitInFrame >= length(msgInBits(:)) 
        frame(1:length(msgInBits(:))) = msgInBits(1 : end);
        numPayloadBitInFrame = length(msgInBits(1:end));
    end  
end