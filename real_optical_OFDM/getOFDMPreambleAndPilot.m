function sig = getOFDMPreambleAndPilot(sigType, varargin)
% GETOFDMPREAMBLEANDPILOT: Return either the preamble OFDM symbols or the
% pilot signals for one frame transmission based on the 802.11a standard.

% Copyright 2014-2016 The MathWorks, Inc.

switch sigType
  case 'Preamble'
    [FFTLen, numGuardBandCarriers] = deal(varargin{:});
    NCGuardBand = 12; 
    LongNumGuardBandCarriers = [6; 6];
    NumCarriersHermitian = FFTLen - NCGuardBand;
    NumDataCarriers      = (NumCarriersHermitian - 2)/2; 
    % Create short preamble
    
    shortPreamble = ...
        [ 0    0  1+1i 0  0    0 -1-1i 0  0    0 ...                % [-27: -17]
          1+1i 0  0    0 -1-1i 0  0    0 -1-1i 0 0 0 1+1i 0 0 0 ... % [-16: -1 ]
          0    0  0    0 -1-1i 0  0    0 -1-1i 0 0 0 1+1i 0 0 0 ... % [ 0 :  15]
          1+1i 0  0    0  1+1i 0  0    0  1+1i 0 0 ].';             % [ 16:  27]
      
    longPreamble = complex(...
        [ 1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,...
          1,  1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1].', 0); 

     v3 = zeros(NumCarriersHermitian,1);
     v4 = zeros(NumCarriersHermitian,1);
     output1 = zeros(NumDataCarriers,1);
     output2 = zeros(NumDataCarriers,1);
     output = complex(v3,v4);
     for k = 1 : 1 : NumDataCarriers
        output1(k) = longPreamble(k);
        output2(k) = conj(longPreamble(NumDataCarriers+1-k));
     end 
     output(:) = cat(1,1,output1,1,output2);
     longPreamble = output; 

    % OFDM preamble modulator
    preambleOFDMMod = comm.OFDMModulator(...
        'FFTLength' ,           FFTLen,...
        'NumGuardBandCarriers', numGuardBandCarriers,...
        'CyclicPrefixLength',   0);
    
    LongpreambleOFDMMod = comm.OFDMModulator(...
    'FFTLength' ,           FFTLen,...
    'NumGuardBandCarriers', LongNumGuardBandCarriers,...
    'CyclicPrefixLength',   0);

    % Modulate and scale short preamble
    shortPreamblePostOFDM = sqrt(13/6)*preambleOFDMMod(shortPreamble);
    % Modulate long preamble
    longPreamblePostOFDM = LongpreambleOFDMMod(longPreamble);

    % Preamble for one frame
    sig = [shortPreamblePostOFDM; ...
           shortPreamblePostOFDM; ...
           shortPreamblePostOFDM(1:end/2); ...
           longPreamblePostOFDM(end/2+1:end); ...
           longPreamblePostOFDM; ...
           longPreamblePostOFDM];
       
    sig = real(sig);
    
       
  case 'Pilot'
    numOFDMSym = varargin{1};
    
    % PN sequence for pilot generation
    obj.pPNSeq = comm.PNSequence(...
        'Polynomial',        [1 0 0 0 1 0 0 1],...
        'SamplesPerFrame',   numOFDMSym,...
        'InitialConditions', [1 1 1 1 1 1 1]);

    % Pilot signals for one frame
    pilotForOneCarrier  = obj.pPNSeq();
    sig = repmat(1 - 2 * pilotForOneCarrier, 1, 1)';
end

end

% [EOF]