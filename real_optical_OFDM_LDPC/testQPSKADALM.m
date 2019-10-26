%constant parameters to calculate the frameLen
FFTLength            = 64;
CyclicPrefixLength   = 16;
NumOFDMSymInPreamble = 13;            %
NumBitsPerCharacter  = 7;            
NumDataCarriers      = 23;            %number of data subcarrier before hermitian symmetry
osf                  = 2;             %Oversampling factor
fs                   = 0.15625e6/osf; %Transmit sample rate in MHz
LDPCMatrix_M         = 5;             %number of columns in LDPC matrix
LDPCMatrix_N         = 100;           %number of rows in lDPC matrix

%message to be send : 
%1) converted first in char
msg       = "test for a given string \n";
msg       = char(msg);
%2) converted then in bits
msgInBits = coder.const(double(dec2bin(msg,NumBitsPerCharacter).')-48);

%Broadband modulation: QPSK : modulation order = 2 / BPSK : modulation
%order = 1 / 16-QAM : modulation order = 16.
modulationType  = 'QPSK';
modulationOrder = 2;

%Number of frame to receive for measurments.
numFrames       = 400;

% release(sdrTransmitter); 
% release(sdrReceiver);

%Prepare frame according to LDPC matrix's size
[frame,nbBitFrame,numPayLoadBitInFrame] = prepareFrame(msgInBits,NumDataCarriers,modulationOrder,LDPCMatrix_M,LDPCMatrix_N);

%data encoding using LDPC
encodedData = generateCodeWord(frame);

%beginning of a header, usefull to find the size of payload message at the
%receiver / could be usefull to implement MAC layer frame structure.
header = coder.const(double(dec2bin(numPayLoadBitInFrame).')'-48);
NumBitInHeader = length(header(1,:));
           
%TRANSMITER: 
% 1) Serial to parallel
% 2) Broadband modulation
% 3) Hermitian symmetry
% 4) pilots insertion
% 5) IFFT
% 6) Cyclic prefix insertion
% 7) adding preamble and header to the frame
OFDMTX = OpticalOFDMTransmitter2('SampleRate',fs,...
                                'MsgInBits',encodedData,...
                                'header',header,...  
                                'ModulationType', modulationType );
                                
% spectrum for transmitted signal
pPSDSA = dsp.SpectrumAnalyzer('Name','Transmited Signal spectrum', ...
                              'SampleRate',fs*osf);

% frame generation
[txSig,ofdmsig,FrameHeader,referenceComplexSig] = OFDMTX();
FrameLength           = OFDMTX.FrameLength+80;
tabFrameLengthOFDMSig = length(ofdmsig);
tabFrameLengthheader  = length(FrameHeader);
tabFrameLength        = length(txSig);
frameLen              = FrameLength;

%PLUTO RADIO%
%Initialize SDR device
deviceNameSDR = 'Pluto'; % Set SDR Device
radio = sdrdev(deviceNameSDR);           % Create SDR device object

% txGain = 0 -> for bad channel conditions
% txGain = -30 -> for very good channel conditions
txGain = -10;

%transmitter initialisation
sdrTransmitter = sdrtx(deviceNameSDR); % Transmitter properties
sdrTransmitter.RadioID = 'usb:0';
sdrTransmitter.BasebandSampleRate = fs*osf;
sdrTransmitter.CenterFrequency = 5.5e8;  % Channel 
sdrTransmitter.ShowAdvancedProperties = true;
sdrTransmitter.Gain = txGain;


% Resample transmit waveform -> resampling to the desired sample rate.
% (resampling reduce BER -> frequency redondancy)
txSig  = resample(txSig,fs*osf,fs);

% Scale the normalized signal to avoid saturation of RF stages
powerScaleFactor = 0.8;
txSig = txSig.*(1/max(abs(txSig))*powerScaleFactor);

% ADALM-Pluto need complex signal (imaginary part = 0)
txSig = complex(txSig);

pPSDSA(txSig); 

%calculation principle parameters : frame size, sample rate, frame time...
[results] = calculateParameters(fs,osf,frameLen,modulationOrder,FFTLength,numPayLoadBitInFrame);

% Transmit RF waveform (transmit reapeat -> signal transmitted forever
% until calling release() function.
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

% Burst capture of the signal
rxSig = sdrReceiver(); 

% downsampling to the initial sample rate
rxSig = resample(rxSig,fs,fs*osf);
       

%RECEIVER%
showMsg = true;
showScopes = false;

% initialisation of the object : 
% 1) timming synchronization/ frame detection using Schmid and Cox algorithm 
% 2) offset frequency correction
% 3) equalization : a) using long preamble b) using pilots
ofdmrx = OpticalOFDMReceiver2( ...
        'SampleRate',fs,...
        'FrameLength',    frameLen, ...
        'DisplayMessage', showMsg,  ...
        'numFrames',numFrames,...
        'ModulationType', modulationType, ...
        'numBitHeader', NumBitInHeader, ...
        'referenceComplexSig', referenceComplexSig, ...
        'LDPCMatrix_M',LDPCMatrix_M,...
        'LDPCMatrix_N',LDPCMatrix_N,...
        'ShowScopes',     showScopes);

%receiving of the encoded bits, symbols (for calculating EVR and the number
%of frame detected (for measurments). 
[decMsgInBits, numFramesDetected,payLoadBit,received_symbols] = ofdmrx(rxSig);

if numFramesDetected <= numFrames
    numFramesMeasur = numFramesDetected;
else
    numFramesMeasur = numFrames;
end

% BER and FER calculation
[FER, BER] = calculateOFDMBER(msg, decMsgInBits, numFramesMeasur);

% EVR calculation
EVR = Calculate_EVR(received_symbols,modulationType,referenceComplexSig,numFramesMeasur);

fprintf('\n %d fames detected  with FER = %f / BER = %f / EVR = %f \n', ...
     numFramesDetected, FER, BER,EVR); 

% stop transmission and reception
release(sdrTransmitter); 
release(sdrReceiver);

% LDPC encoding
function encodedData = generateCodeWord(frame)

    %Generate LDPC codeword for the transmit data. Use base graph number two.
    bgn = 2; 
    encodedData = nrLDPCEncode(frame,bgn);   
    encodedData = reshape(encodedData,1,length(encodedData(:)))';
   
end

% EVR calculation
function EVR = Calculate_EVR(received_symbols,modulationType,referenceComplexSig,numFramesDetected)
    received_symbols = reshape(received_symbols,1,length(received_symbols(:)));
    referenceComplexSig = reshape(referenceComplexSig,1,length(referenceComplexSig(:)));
    referenceComplexSig = repmat(referenceComplexSig,1,numFramesDetected);
    
    % initialization of the reference constellation depending of the
    % broadband constellation
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
    
    % normalization factor computation:
    % normalization factor for reference symbols
    A0 = sqrt(N/sum(real(reference_constellation).^2 + imag(reference_constellation).^2));
    
    % normalization factor for received symbols
    A = sqrt(length(received_symbols(:))/sum(real(received_symbols).^2 + imag(received_symbols).^2));
    
    % mean square error calculation
    error = 1/length(received_symbols(:))*sum(abs(real(received_symbols).*A - real(referenceComplexSig).*A0).^2 + abs(imag(received_symbols).*A - imag(referenceComplexSig).*A0).^2);
    reference_power = 1/length(received_symbols(:))*sum(abs(real(referenceComplexSig).*A0).^2 + abs(imag(referenceComplexSig).*A0).^2);
    
    % Root mean square error calculation (EVR rms)
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

% frame generation
function [frame,nbBitInFrame,numPayloadBitInFrame] = prepareFrame(msgInBits,NumDataCarriers,modulationOrder,LDPCMatrix_M,LDPCMatrix_N)
    % initialization of the frame size, correponding to LDPC matrix's size
    frameSize = LDPCMatrix_M*LDPCMatrix_N;
    
    % payload message
    if modulationOrder == 16
         numPayLoadOFDMSymbols = fix((frameSize)/(NumDataCarriers*log2(modulationOrder)));
         nbBitInFrame = NumDataCarriers*log2(modulationOrder)*numPayLoadOFDMSymbols;
    else
         nbBitInFrame = frameSize;
    end 
    
    % padding bits
    frame = (randi([0 1], nbBitInFrame, 1));
    numPayloadBitInFrame = zeros(1);
    if nbBitInFrame >= length(msgInBits(:)) 
        frame(1:length(msgInBits(:))) = msgInBits(1 : end);
        numPayloadBitInFrame = length(msgInBits(1:end));
    end  
    frame = reshape(frame,LDPCMatrix_N,LDPCMatrix_M);
    nbBitInFrame = [LDPCMatrix_N,LDPCMatrix_M];
end
