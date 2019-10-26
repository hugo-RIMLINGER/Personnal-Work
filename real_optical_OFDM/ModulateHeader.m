classdef (StrictDefaults) ModulateHeader <matlab.System
% OFDMTransmitter Generate OFDM signal repeatedly for a payload message
% based on the 802.11a standard.

% Copyright 2014-2018 The MathWorks, Inc.

properties (Nontunable)
    %SampleRate Sample rate    
    SampleRate = 20e6
    %PayloadMessage Payload message
    PayloadMessage 
    %NumFrames Number of frames to transmit
    NumFrames = 1 
    % Decide which modulation to use before OFDM
    ModulationType = 'QPSK'
    pPayloadBits
end

properties( SetAccess = private, Dependent)
    %FrameLength Frame length
    FrameLength
    NumCarriersHermitian
    NumDataCarriers
end

properties( Access = private)
    pNumPadBits         % Number of random bits padded in each frame
    pNumOFDMSymbols     % Number of OFDM symbols per frame
    pPreamble           % Preamble for each frame
    pPilots             % Pilots for each frame
    pfirstMod            % BPSK Modulator System object
    pDataOFDMMod        % OFDM Modulator System object 
    piloteIndices       %pilote indices
    pNumPadModulatedSymbols
    pNumModulateSymbols
    modulationOrder    
end

properties(Constant, Access = private) % OFDM Modulator configuration
    FFTLength            = 64
    NumGuardBandCarriers = [6; 6]
    CyclicPrefixLength   = 16
    %NumBitsPerCharacter  = 7 % because we chose a type 'char'
    NCGuardBand = 12
    NCPilots = 4
end

methods        
  function obj = ModulateHeader(varargin)
    setProperties(obj, nargin, varargin{:});
  end
  
  function set.SampleRate(obj, Rs)
    propName = 'SampleRate';
    validateattributes(Rs, {'double'}, ...
        {'real','scalar','positive','finite'}, ...
        [class(obj) '.' propName], propName); 
	obj.SampleRate = Rs;
  end
  
  function  set.PayloadMessage(obj, msg)
    propName = 'PayloadMessage';
    validateattributes(msg, {'char','string'}, {'row'}, ... 
        [class(obj) '.' propName], propName); 
    obj.PayloadMessage = char(msg);
  end
  
  function  set.ModulationType(obj, modulationType)
    propName = 'ModulationType';
    validateattributes(modulationType, {'char','string'}, {'row'}, ... 
        [class(obj) '.' propName], propName); 
    
    obj.ModulationType = char(modulationType);
  end
  
  function set.NumFrames(obj, numFrm)
    propName = 'NumFrames';
    validateattributes(numFrm, {'double'}, ... 
        {'real','scalar','positive','integer','finite'}, ... 
        [class(obj) '.' propName], propName); 
    obj.NumFrames = numFrm;
  end
  
  function set.pPayloadBits(obj, msgInBits)
    obj.pPayloadBits = msgInBits;
    obj.pPayloadBits = reshape(obj.pPayloadBits,1,length(obj.pPayloadBits(:)))';
  end
  
  function NumCarriersHermitian = get.NumCarriersHermitian(obj)
    NumCarriersHermitian =  obj.FFTLength  - obj.NCGuardBand;
  end
  
  function NumDataCarriers = get.NumDataCarriers(obj)
    NumDataCarriers      = (obj.NumCarriersHermitian - 2)/2 - obj.NCPilots/2;
  end
  
  function frameLen = get.FrameLength(obj)
    frameLen = ceil(length(obj.pPayloadBit(:))/(obj.NumDataCarriers*obj.modulationOrder)) * ...
               (obj.FFTLength+obj.CyclicPrefixLength);
  end
end

methods(Access = protected)
  function setupImpl(obj)
    coder.extrinsic('dec2bin','getOFDMPreambleAndPilot');
    
    setUpModulation(obj); 

    % Get pilot for each frame
    obj.pPilots = coder.const(double(getOFDMPreambleAndPilot('Pilot', obj.pNumOFDMSymbols)));

    % OFDM modulator
    obj.pDataOFDMMod = comm.OFDMModulator(...
        'FFTLength' ,           obj.FFTLength, ...
        'NumGuardBandCarriers', obj.NumGuardBandCarriers, ...
        'CyclicPrefixLength',   obj.CyclicPrefixLength, ...
        'NumSymbols',           obj.pNumOFDMSymbols);

  end
  
  function resetImpl(obj)
    reset(obj.pfirstMod);
    reset(obj.pDataOFDMMod);
  end
  
  function y = stepImpl(obj)  
      
    % QPSK modulation for one frame 
    symPostQPSK = modulateBit(obj);
    
    %insert pilot and calculate pilot's indices 
    [symBeforeHermitian, obj.piloteIndices] = insertPilot(symPostQPSK, obj); 
    
    %apply hermitian symmetry
    symPostHermitian = applyHermitianSymmetry(symBeforeHermitian, obj);  

    
    % OFDM modulation for one frame
    symPostOFDM = obj.pDataOFDMMod(...
        symPostHermitian);
    
    % Repeat the frame
    y = symPostOFDM;
  end
  
  function releaseImpl(obj)
    release(obj.firstMod);
    release(obj.pDataOFDMMod);
  end
  

function y= applyHermitianSymmetry(symPostBPSK, obj)
     v3 = zeros(obj.NumCarriersHermitian,obj.pNumOFDMSymbols);
     v4 = zeros(obj.NumCarriersHermitian,obj.pNumOFDMSymbols);
     output1 = zeros(obj.NumDataCarriers+2,1);
     output2 = zeros(obj.NumDataCarriers+2,1);
     output = complex(v3,v4);
    for j = 1 : 1 : obj.pNumOFDMSymbols
         for k = 1 : 1 : obj.NumDataCarriers+2
           output1(k) = symPostBPSK(k,j);
           output2(k) = conj(symPostBPSK(obj.NumDataCarriers+3-k,j));
         end 
         output(:,j) = cat(1,0,output1,0,output2);
    end
    y = output;
    
end

function [output , pilotIndice] = insertPilot(symPostQPSK, obj)
    piloteIndice1 = 4;
    piloteIndice2 = 18;
    output = [symPostQPSK(1:piloteIndice1,:); obj.pPilots; symPostQPSK(piloteIndice1+1:end,:)];
    output = [output(1:piloteIndice2,:); obj.pPilots; output(piloteIndice2+1:end,:)];
    pilotIndice = [piloteIndice1; piloteIndice2; obj.NumDataCarriers+1 + (obj.NumDataCarriers+1-piloteIndice2 + 2); ...
                        obj.NumDataCarriers+1 + (obj.NumDataCarriers+1-piloteIndice1 +2)];
    pilotIndice = pilotIndice +2;
end

function setUpModulation(obj)
    switch obj.ModulationType 
        
        case 'BPSK'
            obj.modulationOrder = 1;
            % Calculate number of OFDM symbols per frame
            obj.pNumOFDMSymbols = ceil(length(obj.pPayloadBits)/obj.NumDataCarriers);
            % Calculate number of bits padded in each frame
            obj.pNumPadBits = obj.NumDataCarriers * obj.pNumOFDMSymbols - length(obj.pPayloadBits);
            obj.pfirstMod = comm.BPSKModulator;  
            
        case 'QPSK'
            obj.modulationOrder = 2;
            if mod(length(obj.pPayloadBits),2) ~= 0 
                obj.pPayloadBits = cat(1,obj.pPayloadBits,1);
            end

            obj.pNumModulateSymbols = ceil(length(obj.pPayloadBits)/obj.modulationOrder);

            obj.pNumOFDMSymbols = ceil(obj.pNumModulateSymbols/(obj.NumDataCarriers));

            % Calculate number of bits padded in each frame
            obj.pNumPadModulatedSymbols = obj.NumDataCarriers * obj.pNumOFDMSymbols - obj.pNumModulateSymbols;
            obj.pNumPadBits = obj.pNumPadModulatedSymbols*obj.modulationOrder;
            obj.pfirstMod = comm.QPSKModulator(...
                 'BitInput', true);
        case 'QAM'
            obj.modulationOrder = 16;
            if mod(length(obj.pPayloadBits),log2(obj.modulationOrder)) ~= 0 
                if  mod(length(obj.pPayloadBits),log2(obj.modulationOrder)) < log2(obj.modulationOrder)
                    padBits = zeros(1,abs(mod(length(obj.pPayloadBits),log2(obj.modulationOrder))-log2(obj.modulationOrder)))';
                    obj.pPayloadBits = cat(1,obj.pPayloadBits,padBits);
                else
                    padBits = zeros(1,mod(length(obj.pPayloadBits),log2(obj.modulationOrder)))';
                    obj.pPayloadBits = cat(1,obj.pPayloadBits,padBits);
                end
            end

            obj.pNumModulateSymbols = ceil(length(obj.pPayloadBits)/log2(obj.modulationOrder));

            obj.pNumOFDMSymbols = ceil(obj.pNumModulateSymbols/(obj.NumDataCarriers));

            % Calculate number of bits padded in each frame
            obj.pNumPadModulatedSymbols = obj.NumDataCarriers * obj.pNumOFDMSymbols - obj.pNumModulateSymbols;
            obj.pNumPadBits = obj.pNumPadModulatedSymbols*log2(obj.modulationOrder);
    end
    
            
end

function [symPostQPSK] = modulateBit(obj)
    switch obj.ModulationType
        case 'QPSK' 
            symPostQPSK = obj.pfirstMod(...
                    [obj.pPayloadBits]);
            release(obj.pfirstMod);
            signalPad = obj.pfirstMod(randi([0 1], obj.pNumPadBits, 1));
            symPostQPSK = cat(1,symPostQPSK,signalPad);
            symPostQPSK = reshape(symPostQPSK, obj.NumDataCarriers, obj.pNumOFDMSymbols);
        case 'BPSK' 
            symPostQPSK = obj.pfirstMod(...
                    [obj.pPayloadBits]);
            release(obj.pfirstMod);
            signalPad = obj.pfirstMod(randi([0 1], obj.pNumPadBits, 1));
            symPostQPSK = cat(1,symPostQPSK,signalPad);
            symPostQPSK = reshape(symPostQPSK, obj.NumDataCarriers, obj.pNumOFDMSymbols);
        case 'QAM'
            symPostQAM = qammod(obj.pPayloadBits,obj.modulationOrder,'InputType','bit');
            signalPad = zeros(obj.pNumPadBits,1);
            signalPad = qammod(signalPad,obj.modulationOrder,'InputType','bit');
            symPostQAM1 = cat(1,symPostQAM,signalPad);
            symPostQPSK = reshape(symPostQAM1, obj.NumDataCarriers, obj.pNumOFDMSymbols);

    end 

end


end

end

% [EOF]
