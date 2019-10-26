classdef (StrictDefaults) OpticalOFDMReceiver2 < matlab.System
% OFDMReceiver Recover payload message from the time domain OFDM input
% signal based on the 802.11a standard.

% Copyright 2014-2016 The MathWorks, Inc.

properties (Nontunable)
    %SampleRate Sample rate
    SampleRate  = 20e6
    %FrameLength Frame length
    FrameLength
    ModulationType
    header
    numBitHeader
    referenceComplexSig
    numFrames
    LDPCMatrix_M
    LDPCMatrix_N  
    LDPC_coding_rate = 5
end

properties (Logical, Nontunable)    
    %DisplayMessage Display decoded message
    DisplayMessage = true
    %ShowScopes Show scopes
    ShowScopes = true
end

properties(Nontunable, Access = private)
    pNumOFDMSymbols         % Number of OFDM symbols per frame
    pNumBitsPerDisplay      % Number of bits converted to letters for display
    pPilotIndexInPreamble   % Pilot subcarrier indices in preamble symbols
    pDataIndexInPreamble    % Data subcarrier indices in preamble symbols
    pPreamble               % Preamble for each frame
    pPilots                 % Pilots for each frame
    pBufferLength           % Moving buffer size at receiver
    pSlideDistance          % Incremental distance window
    pfirstMod              % BPSK Demodulator System object
    pPreambleOFDMDemod      % OFDM Demodulator System object for short preamble
    pDataOFDMDemod          % OFDM Demodulator System object for data
    pPreambleOFDMDemodLong  % OFDM Modulator for Long Preamble
    pDataOFDMDemodHeader    %OFDM demodulator for header
    pScopes                 % OFDM Scopes System object
end

properties(Access = private) 
    pFreqOffsetEstBuffer    % Buffer for estimating frequency offset
    pNumFrameDetected       % Number of detected frames
    LongPreamble            % Long Preamble for phase and frequency offset correction
    NumCarriersHermitian
    NumDataCarriersLongPreamble
    NumDataCarriers
    pNumFramePlotted % Number of frames plotted in time scope
    pCurrentFrame    % Current frame input to the time scope
    pTS              % Time Scope System object to display frame detection and estimated frequency offsets
    pEqGainAP        % Array Plot System object to display equalizer gains
    pPSDSA           % Spectrum Analyzer System object to display PSD
    pPreEqCD         % Constellation Diagram System object to show symbols before equalization
    pPostEqCD        % Constellation Diagram System object to show symbols after equalization
    modulationOrder  
    NumOFDMSymInPreamble
    scope
end 

properties(Constant, Access = private) 
    % OFDM Demodulator configuration
    
    NumFrames = 1;
    FFTLength= 64;
    NCGuardBand = 12; 
    NCPilots = 4;
    NumGuardBandCarriers = [6; 6]; %must be symmetric 
    NumGuardBandCarriersPreamble = [6 ; 5];
    NumShortPreamble = 2;
    NumLongPreamble = 2;
    CyclicPrefixLength   = 16;
    NumBitsPerCharacter  = 7; %'char'
    PilotCarrierIndices  = [12;26;40;54];
    BufferToFrameLenRatio = 1.5;
    FrameToSliderLenRatio = 4;
    NumOFDMSymbolHeader = 1;
    headerLen = 80;
    numPayloadBitHeader =  28;
    
    % A few adjustable algorithms parameters:
    %   1). Number of frequency estimates to be averaged over for frequency corrections
    NumFreqToAverage = 20 
    %   2). Peak threshold after normalization for preamble detection 
    PeakThreshold = 0.6
    %   3). Mininum number of peaks for positive match in frame detection
    MinNumPeaksForMatch = 6
end

methods
  function obj = OpticalOFDMReceiver2(varargin)
    setProperties(obj, nargin, varargin{:});
  end
  
  function set.SampleRate(obj, Rs)
    propName = 'SampleRate';
    validateattributes(Rs, {'double'}, ...
        {'real','scalar','positive','finite'}, ...
        [class(obj) '.' propName], propName); 
    
	obj.SampleRate = Rs;
  end
  
  function set.referenceComplexSig(obj, refComplexSig)
	obj.referenceComplexSig = refComplexSig;
  end
  
  function set.numBitHeader(obj, numBitInHeader)
    propName = 'numBitHeader';
    validateattributes(numBitInHeader, {'double'}, ...
        {'real','scalar','positive','finite'}, ...
        [class(obj) '.' propName], propName); 
    
	obj.numBitHeader = numBitInHeader;
  end
  
  function  set.ModulationType(obj, modulationType)
    propName = 'ModulationType';
    validateattributes(modulationType, {'char','string'}, {'row'}, ... 
        [class(obj) '.' propName], propName); 
    
    obj.ModulationType = char(modulationType);
  end
  
  function set.FrameLength(obj, frameLen)
    propName = 'FrameLength';
    validateattributes(frameLen, {'double'}, ... 
        {'real','scalar','positive','integer','finite'}, ... 
        [class(obj) '.' propName], propName); 
    
    obj.FrameLength = frameLen;
  end  
  
  function set.numFrames(obj, numFrames)
    propName = 'numFrames';
    validateattributes(numFrames, {'double'}, ... 
        {'real','scalar','positive','integer','finite'}, ... 
        [class(obj) '.' propName], propName); 
    
    obj.numFrames= numFrames;
  end 
    
  function set.LDPCMatrix_M(obj, LDPCMatrix_M)
      propName = 'LDPCMatrix_M';
      validateattributes(LDPCMatrix_M, {'double'}, ... 
          {'real','scalar','positive','integer','finite'}, ... 
          [class(obj) '.' propName], propName); 

      obj.LDPCMatrix_M= LDPCMatrix_M;
  end 

  function set.LDPCMatrix_N(obj, LDPCMatrix_N)
      propName = 'LDPCMatrix_M';
      validateattributes(LDPCMatrix_N, {'double'}, ... 
          {'real','scalar','positive','integer','finite'}, ... 
          [class(obj) '.' propName], propName); 

      obj.LDPCMatrix_N= LDPCMatrix_N;
  end 
  
end

methods(Access = protected)
  function validateInputsImpl(obj, x)
    % Validate data input
    validateattributes(x, {'double'}, {'column','nonempty','finite'}, ...
        [class(obj) '.' 'Input'], 'the signal input');      
  end
  
  function setupImpl(obj)
    coder.extrinsic('setdiff', 'getOFDMPreambleAndPilot');
    
    setUpModulation(obj);
    
    % Constant calculation
    obj.NumOFDMSymInPreamble = obj.NumShortPreamble + obj.NumLongPreamble +1;
    obj.NumCarriersHermitian = obj.FFTLength - obj.NCGuardBand;
    obj.NumDataCarriersLongPreamble = (obj.NumCarriersHermitian - 2)/2;
    obj.NumDataCarriers      = (obj.NumCarriersHermitian - 2)/2 - obj.NCPilots/2; 
    obj.pNumOFDMSymbols = (obj.FrameLength - obj.NumOFDMSymInPreamble * obj.FFTLength) / ...
        (obj.FFTLength + obj.CyclicPrefixLength)-1;
    obj.pNumBitsPerDisplay = floor(obj.pNumOFDMSymbols*obj.modulationOrder*...
        obj.NumDataCarriers/obj.NumBitsPerCharacter)*obj.NumBitsPerCharacter;
    obj.pBufferLength  = ceil(obj.FrameLength*obj.BufferToFrameLenRatio);
    obj.pSlideDistance = ceil(obj.FrameLength/obj.FrameToSliderLenRatio);  

    % Calculate locations of pilots without guardbands in preambles
    obj.pPilotIndexInPreamble = obj.PilotCarrierIndices - obj.NumGuardBandCarriersPreamble(1);
    
    % Calculate locations of data without guardbands in preambles
    obj.pDataIndexInPreamble  = coder.const(double(setdiff((1:obj.NumCarriersHermitian)'', ...
        sort([obj.PilotCarrierIndices; obj.FFTLength/2+1] - obj.NumGuardBandCarriersPreamble(1)))));    
    
    % Get preamble for each frame
    obj.pPreamble = coder.const(double(getOFDMPreambleAndPilot('Preamble', obj.FFTLength, obj.NumGuardBandCarriersPreamble)));
    
    % Get pilot for each frame
    obj.pPilots = coder.const(double(getOFDMPreambleAndPilot('Pilot', obj.pNumOFDMSymbols)));
    
    %Get LongPreamble real 
    obj.LongPreamble = complex(...
            [ 1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,...
              1,  1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1].', 0);

    obj.LongPreamble = applyHermitianForPreamble(obj.LongPreamble,obj);

    obj.scope = dsp.TimeScope('SampleRate',obj.SampleRate,'TimeSpan',0.0001,'YLimits',[-1,1]);
     
    % OFDM demodulator for preamble
    obj.pPreambleOFDMDemod = comm.OFDMDemodulator( ...
        'FFTLength' ,           obj.FFTLength, ...
        'NumGuardBandCarriers', obj.NumGuardBandCarriersPreamble, ...
        'CyclicPrefixLength',   0, ...
        'NumSymbols',           2);  
    
    obj.pPreambleOFDMDemodLong = comm.OFDMDemodulator( ...
        'FFTLength' ,           obj.FFTLength, ...
        'NumGuardBandCarriers', obj.NumGuardBandCarriers, ...
        'CyclicPrefixLength',   0, ...
        'NumSymbols',           2); 
    
    % OFDM demodulator for data
    obj.pDataOFDMDemod = comm.OFDMDemodulator( ...
        'FFTLength' ,           obj.FFTLength, ...
        'NumGuardBandCarriers', obj.NumGuardBandCarriers, ...
        'RemoveDCCarrier',      true, ...
        'PilotOutputPort',      true, ...
        'PilotCarrierIndices',  obj.PilotCarrierIndices, ...
        'CyclicPrefixLength',   obj.CyclicPrefixLength, ...
        'NumSymbols',           obj.pNumOFDMSymbols);
    
    obj.pDataOFDMDemodHeader = comm.OFDMDemodulator( ...
        'FFTLength' ,           obj.FFTLength, ...
        'NumGuardBandCarriers', obj.NumGuardBandCarriers, ...
        'RemoveDCCarrier',      true, ...
        'CyclicPrefixLength',   obj.CyclicPrefixLength, ...
        'PilotOutputPort',      true, ...
        'PilotCarrierIndices',  obj.PilotCarrierIndices, ...
        'NumSymbols',           1);

    obj.pPSDSA = dsp.SpectrumAnalyzer( ...
    'Name',      'PSD of Detected Frames', ...
    'SampleRate', obj.SampleRate);

    obj.pPreEqCD = comm.ConstellationDiagram( ...
        'ReferenceConstellation', [1; -1], ...
        'Name',                   'Detected Symbols Before Equalization for 1st Data Subcarrier', ...
        'XLimits',                [-4 4], ...
        'YLimits',                [-4 4]);

    obj.pPostEqCD = comm.ConstellationDiagram( ...
        'ReferenceConstellation', [1; -1], ...
        'Name',                   'Detected Symbols After Equalization for 1st Data Subcarrier ', ...
        'XLimits',                [-4 4], ...
        'YLimits',                [-4 4]);
        
  end
  
  function resetImpl(obj)
    obj.pFreqOffsetEstBuffer = zeros(1, obj.NumFreqToAverage);
    obj.pNumFrameDetected = 0;    
    reset(obj.pfirstMod);
    reset(obj.pPreambleOFDMDemod);
    reset(obj.pDataOFDMDemod);
    reset(obj.pPSDSA);
    reset(obj.pPreEqCD);
    reset(obj.pPostEqCD);
  end

  function [y, numFramesDetected,numPayLoadBit,received_symbols] = stepImpl(obj, x)
    coder.extrinsic('num2str','processOFDMScopes');
    
    frameLen = obj.FrameLength;
    bufferLen = min(obj.pBufferLength, length(x));
    detFrmAtBeginning  = obj.pNumFrameDetected;
    
    % Start index for the last moving buffer in this input
    lastBufferStartIdx = max(1, length(x) - bufferLen + 1); 
    
    % Initialization
    y = zeros(1, 0);  
    received_symbols = zeros(1,0);
    bufferStartIdx = 1;  
    test = 1;
    % Moving buffer for frame detection and message recovery        
    while bufferStartIdx <= lastBufferStartIdx
        % Current buffer
        buffer = x(bufferStartIdx + (0:bufferLen-1));
        
        % Find preamble in buffer: Return -1 if finding nothing
        [preambleStartLocation] = locatePreamble(obj, buffer);

        % Check if this buffer holds a full frame
        frameDetected = (preambleStartLocation ~= -1 ) && ...
            ((preambleStartLocation + obj.FrameLength) <= bufferLen);

        % Recover message from the detected frame
        if frameDetected
            obj.pNumFrameDetected = obj.pNumFrameDetected + 1;

            % Extract single frame from buffer
            oneFrameToProcess = buffer(preambleStartLocation + (1:frameLen));

            % Correct frequency offset
            [oneFrameToProcess, estFreqOffset,phi] = coarseFreqCorrection(obj, oneFrameToProcess);

            % Apply equalizers
            [postEqData, preEqData, eqGains] = frameEqualization(obj, oneFrameToProcess);
            
            demodulatedData = postEqData(2: obj.NumDataCarriers+1, :);
            
            %averageMagnitude =  calculateMagnitude(obj,demodulatedData);
            
            %data demodulation
            decMsgInBits = demodulateSig(obj,demodulatedData(:));
            
             decodedData = decodeLDPC(obj,decMsgInBits);
             
            %header demodulation and payloadBit size extraction
            demodulatedHeader = HeaderEqualization(obj, oneFrameToProcess);
            
            %demodulate header 
            demodulatedHeader = demodulatedHeader(2: obj.NumDataCarriers+1, :);
            bitHeader =  demodulateSig(obj,demodulatedHeader(:));
            
            %find payload bit size (contain in header)
            testheader(1:obj.numBitHeader) = num2str(bitHeader(1:obj.numBitHeader,1))';
            numPayLoadBit = coder.const(double(bin2dec(testheader)));
            
            %stop saving bit when number of frame > 100
            if obj.pNumFrameDetected > obj.numFrames
                disp('number of frame for measurements is enought');
                obj.pNumFrameDetected = obj.pNumFrameDetected - 1;
            else
                %no display if payload bit is wrong (182 = known value)
                if numPayLoadBit ~= 182 
                    disp('an error occure during the demodulation of the header');
                    y = [y, decodedData(:)'];
                    received_symbols = [received_symbols,demodulatedData];
                else  
                    %save payloadBits
                    y = [y, decodedData(:)'];
                    received_symbols = [received_symbols,demodulatedData];
                    recovered_msgInbits = reshape(decodedData(1:numPayLoadBit),[7, floor((length(decodedData(1:numPayLoadBit)'))/7)])';
                    recovered_message = char(bin2dec(num2str(recovered_msgInbits)))'; 
                    disp(recovered_message);   
                end
            end 
            
            if obj.ShowScopes % Visualization
                % 2). Array Plot for preamble and pilot equalization gains
                %obj.pEqGainAP(abs(eqGains(:, [1, 1+obj.SymbolIndexToDisplay])));

                % 3). Spectrum Analyzer for PSD
                obj.pPSDSA(oneFrameToProcess); 

                % 4). Constellation Diagram for BPSK symbols before equalizations
                obj.pPreEqCD(preEqData (2:20, :).');

                % 5). Constellation Diagram for BPSK symbols after equalizations
                obj.pPostEqCD(postEqData(2:20, :).');
            end
                        
            if bufferStartIdx < lastBufferStartIdx % Jump a frame, about 4 windows
                bufferStartIdx = min(bufferStartIdx + frameLen, lastBufferStartIdx);
            else % Window sliding
                bufferStartIdx = bufferStartIdx + obj.pSlideDistance; 
            end            
        else % Window sliding
            bufferStartIdx = bufferStartIdx + obj.pSlideDistance; 
            disp('hello');
        end                        
    end
    numFramesDetected = obj.pNumFrameDetected - detFrmAtBeginning; 
  end
  
  function releaseImpl(obj)
    release(obj.pfirstMod);
    release(obj.pPreambleOFDMDemod);
    release(obj.pDataOFDMDemod);
    release(obj.pPSDSA);
    release(obj.pPreEqCD);
    release(obj.pPostEqCD);
  end
  
  function s = saveObjectImpl(obj)
    s = saveObjectImpl@matlab.System(obj);
    if isLocked(obj)
        s.pBPSKDemod            = matlab.System.saveObject(obj.pBPSKDemod);
        s.pPreambleOFDMDemod    = matlab.System.saveObject(obj.pPreambleOFDMDemod);        
        s.pDataOFDMDemod        = matlab.System.saveObject(obj.pDataOFDMDemod);
        s.pScopes               = matlab.System.saveObject(obj.pScopes);        
        s.pNumOFDMSymbols       = obj.pNumOFDMSymbols;
        s.pNumBitsPerDisplay    = obj.pNumBitsPerDisplay;
        s.pPilotIndexInPreamble = obj.pPilotIndexInPreamble;
        s.pDataIndexInPreamble  = obj.pDataIndexInPreamble;
        s.pPreamble             = obj.pPreamble;
        s.pPilots               = obj.pPilots;
        s.pBufferLength         = obj.pBufferLength;
        s.pSlideDistance        = obj.pSlideDistance;
        s.pFreqOffsetEstBuffer  = obj.pFreqOffsetEstBuffer;
        s.pNumFrameDetected     = obj.pNumFrameDetected;
    end      
  end
  
  function loadObjectImpl(obj, s, wasLocked)
    if wasLocked
        obj.pBPSKDemod            = matlab.System.loadObject(s.pBPSKDemod);
        obj.pPreambleOFDMDemod    = matlab.System.loadObject(s.pPreambleOFDMDemod);
        obj.pDataOFDMDemod        = matlab.System.loadObject(s.pDataOFDMDemod);
        obj.pScopes               = matlab.System.saveObject(s.pScopes);
        obj.pNumOFDMSymbols       = s.pNumOFDMSymbols;
        obj.pNumBitsPerDisplay    = s.pNumBitsPerDisplay;
        obj.pPilotIndexInPreamble = s.pPilotIndexInPreamble;
        obj.pDataIndexInPreamble  = s.pDataIndexInPreamble;
        obj.pPreamble             = s.pPreamble;
        obj.pPilots               = s.pPilots;
        obj.pBufferLength         = s.pBufferLength;
        obj.pSlideDistance        = s.pSlideDistance;
        obj.pFreqOffsetEstBuffer  = s.pFreqOffsetEstBuffer;
        obj.pNumFrameDetected     = s.pNumFrameDetected;
    end
    loadObjectImpl@matlab.System(obj, s);
  end
  
  function flag = isInputSizeLockedImpl(~,~)
    flag = false;
  end
  
  function flag = isInputComplexityLockedImpl(~,~)
    flag = true;
  end
  
  function flag = isOutputComplexityLockedImpl(~,~)
    flag = true;
  end
  
  function setUpModulation(obj)
      switch obj.ModulationType 
        
            case 'BPSK'
                obj.modulationOrder = 1;
                obj.pfirstMod = comm.BPSKDemodulator;  
            case 'QPSK'
                obj.modulationOrder = 2;
                obj.pfirstMod = comm.QPSKDemodulator(...
                    'BitOutput',true);
          case 'QAM'
              obj.modulationOrder = 16;
      end
  end 
  
  function demodulatedData = demodulateSig(obj,postOFDMDemod)
      switch obj.ModulationType
          case 'BPSK'
              demodulatedData = obj.pfirstMod(postOFDMDemod(:));
              release(obj.pfirstMod);
          case 'QPSK'
              demodulatedData = obj.pfirstMod(postOFDMDemod(:));
              release(obj.pfirstMod);
          case 'QAM'
              demodulatedData = qamdemod(postOFDMDemod(:),obj.modulationOrder,'OutputType','bit');
              
      end 
                  
  end
  
  function decodedData = decodeLDPC(obj,decMsgInBits)
    decMsgInBits = reshape(decMsgInBits,1,length(decMsgInBits(:)));
    decMsgInBits = decMsgInBits(1:obj.LDPCMatrix_M*obj.LDPCMatrix_N*obj.LDPC_coding_rate);
    decMsgInBits = reshape(decMsgInBits,obj.LDPCMatrix_N*obj.LDPC_coding_rate,obj.LDPCMatrix_M);
    bgn = 2;

    %sof bit convertion, necessary for decoding.
    received_encoded_bit = double(1-2*decMsgInBits);    

   [decodedData,actualniters] = nrLDPCDecode(received_encoded_bit,bgn,25);  
  end
   
end

methods (Access = private)  
  function [preambleStartLocation] = locatePreamble(obj, x)
    % Locate the starting point of the preamble using cross correlation.
    
    L = obj.FFTLength;
    K = obj.FFTLength/4; 
    known = obj.pPreamble(1:K);
    windowLength = ceil(0.5*obj.FrameLength + length(obj.pPreamble));

    % Cross correlate
    rWin = x(1: windowLength-L+K-1);
    Phat = xcorr(rWin, conj(known));
    Rhat = xcorr(abs(rWin).^2, ones(K,1)); % Moving average

    % Remove leading and tail zeros overlaps
    PhatShort = Phat(ceil(length(Phat)/2):end-K/2+1-8);
    RhatShort = Rhat(ceil(length(Rhat)/2):end-K/2+1-8);

    % Calculate timing metric
    M = abs(PhatShort).^2 ./ RhatShort.^2;
    
    % Determine start of short preamble. First find peak locations
    MLocations = find(M > (max(M)*obj.PeakThreshold));

    % Correct estimate to the start of preamble, not its center
    MLocations = MLocations - (K/2+1)+8;

    % Determine correct peaks
    peaks = zeros(size(MLocations));
    desiredPeakLocations = (K:K:obj.NumShortPreamble*L)';
    for i = 1:length(MLocations)
        MLocationGuesses = MLocations(i) + desiredPeakLocations;
        peaks(i) = length(intersect(MLocations(i:end), MLocationGuesses));
    end

    % Have at least obj.pNumRequiredPeaks peaks for positive match    
    peaks(peaks < obj.MinNumPeaksForMatch) = 0;
    % Pick earliest peak in time
    [numPeaks, frontPeakLocation] = max(peaks);
    if ~isempty(peaks) && (numPeaks > 0)
        preambleStartLocation = MLocations(frontPeakLocation);
    else % No desirable location found
        preambleStartLocation = -1; 
    end
  end

  function [y, estFreqOffset,phi] = coarseFreqCorrection(obj, x)
    % Frequency correction based on the Schmidl and Cox method, utilizing
    % halves of the short preamble from the 802.11a standard.
    
    Ts = 1/obj.SampleRate;
    halfFFTLen = obj.FFTLength/2;
    freqOffsetBufferLen = obj.NumFreqToAverage;
    
    % Cross-correlate preamble and determine phase angle
    phi = angle(sum(conj(x(1:halfFFTLen)) .* x(halfFFTLen+(1:halfFFTLen)))); 
                     
    % Update frequency offset buffer
    bufferIdx = mod(obj.pNumFrameDetected - 1, freqOffsetBufferLen) + 1;
    obj.pFreqOffsetEstBuffer(bufferIdx) = phi/(2 * pi * halfFFTLen * Ts);
    
    % Estimated frequency offset     
    estFreqOffset = mean(obj.pFreqOffsetEstBuffer(1:min(freqOffsetBufferLen, obj.pNumFrameDetected)));
 
    % Apply frequency correction
    y = exp(1i * estFreqOffset * (0 : (length(x)-1))' * Ts) .* x;
  end
  
  function [postEqData, demodData, eqGains] = frameEqualization(obj, x)
    % Equalize the OFDM frame through the use of both the long preamble
    % from the 802.11a standard and four pilot tones in the data frames.
    % The gains from the pilots are interpolated across frequency and
    % applied to all data subcarriers.
    
    % Use long preamble frame to estimate channel in frequency domain
    FFTLen = obj.FFTLength;

    % Demodulate received long preamble
    recLongPreamble = x((obj.NumShortPreamble+1)*FFTLen + (1:obj.NumLongPreamble*FFTLen));
    decLongPreamble = obj.pPreambleOFDMDemodLong(recLongPreamble);

    % Get preamble equalizer gains
    preambleNorm = decLongPreamble ./ [obj.LongPreamble, obj.LongPreamble];
    preambleEqGains = conj(mean(preambleNorm, 2)) ./ mean(abs(preambleNorm).^2, 2);    
    
    % Separate data from preambles and demodulate them
    recData = x(obj.NumOFDMSymInPreamble*FFTLen+81:end);
    [demodData, demodPilots] = obj.pDataOFDMDemod(recData);
        
    % Apply preamble equalizer gains to data and pilots
    preambleEqGainsOnPilots = preambleEqGains(obj.pPilotIndexInPreamble);
    preambleEqGainsOnData   = preambleEqGains(obj.pDataIndexInPreamble);
    postEqPilots = repmat(preambleEqGainsOnPilots, [1, obj.pNumOFDMSymbols]) .* demodPilots;
    postEqData   = repmat(preambleEqGainsOnData,   [1, obj.pNumOFDMSymbols]) .* demodData; 
    
    % Get pilot equalizer gains
    pilotNorm = postEqPilots ./ obj.pPilots;
    pilotEqGains = conj(pilotNorm) ./ (abs(pilotNorm).^2);
    
    % Interpolate to data subcarrier size and apply pilot equalizer
    pilotEqGainsOnData = resample(pilotEqGains, (obj.NumCarriersHermitian-obj.NCPilots)/(size(obj.pPilots, 1)*4), 1);
    pilotEqGainsOnData = pilotEqGainsOnData(1:size(pilotEqGainsOnData)-1,:);
    postEqData = pilotEqGainsOnData .* postEqData;
    eqGains = [preambleEqGainsOnData, pilotEqGainsOnData];
  end  
  
  function [demodulatedHeader] = HeaderEqualization(obj, x)
    % Equalize the OFDM frame through the use of both the long preamble
    % from the 802.11a standard and four pilot tones in the data frames.
    % The gains from the pilots are interpolated across frequency and
    % applied to all data subcarriers.
    
    % Use long preamble frame to estimate channel in frequency domain
    FFTLen = obj.FFTLength;

    % Demodulate received long preamble
    recLongPreamble = x((obj.NumShortPreamble+1)*FFTLen + (1:obj.NumLongPreamble*FFTLen));
    decLongPreamble = obj.pPreambleOFDMDemodLong(recLongPreamble);

    % Get preamble equalizer gains
    preambleNorm = decLongPreamble ./ [obj.LongPreamble, obj.LongPreamble];
    preambleEqGains = conj(mean(preambleNorm, 2)) ./ mean(abs(preambleNorm).^2, 2);    
    
    % Separate data from preambles and demodulate them
    recData = x(obj.NumOFDMSymInPreamble*FFTLen+1:obj.NumOFDMSymInPreamble*FFTLen+80);
    [demodData, demodPilots] = obj.pDataOFDMDemodHeader(recData);
        
    % Apply preamble equalizer gains to data and pilots
    preambleEqGainsOnPilots = preambleEqGains(obj.pPilotIndexInPreamble);
    preambleEqGainsOnData   = preambleEqGains(obj.pDataIndexInPreamble);
    postEqPilots = repmat(preambleEqGainsOnPilots, [1, obj.pNumOFDMSymbols]) .* demodPilots;
    postEqData   = repmat(preambleEqGainsOnData,   [1, obj.pNumOFDMSymbols]) .* demodData; 
    
    % Get pilot equalizer gains
    pilotNorm = postEqPilots ./ obj.pPilots;
    pilotEqGains = conj(pilotNorm) ./ (abs(pilotNorm).^2);
    
    % Interpolate to data subcarrier size and apply pilot equalizer
    pilotEqGainsOnData = resample(pilotEqGains, (obj.NumCarriersHermitian-obj.NCPilots)/(size(obj.pPilots, 1)*4), 1);
    pilotEqGainsOnData = pilotEqGainsOnData(1:size(pilotEqGainsOnData)-1,:);
    demodulatedHeader = pilotEqGainsOnData .* postEqData;
    eqGains = [preambleEqGainsOnData, pilotEqGainsOnData];
    
  end  
  
  function output = applyHermitianForPreamble(LongPreamble,obj) 
    v3 = zeros(obj.NumCarriersHermitian,1);
    v4 = zeros(obj.NumCarriersHermitian,1);
    output1 = zeros(obj.NumDataCarriersLongPreamble,1);
    output2 = zeros(obj.NumDataCarriersLongPreamble,1);
    output = complex(v3,v4);
    for k = 1 : 1 : obj.NumDataCarriersLongPreamble
       output1(k) = LongPreamble(k);
       output2(k) = conj(LongPreamble(obj.NumDataCarriersLongPreamble+1-k));
    end 
    output(:) = cat(1,1,output1,1,output2);
  end
  
end 
end

% [EOF]