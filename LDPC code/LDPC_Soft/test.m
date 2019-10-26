% test
clear all;
% Generator Matrix REGULAR
H = [  0 1 0 1 1 0 0 1 ;
      1 1 1 0 0 1 0 0 ;
      0 0 1 0 0 1 1 1 ;
      1 0 0 1 1 0 1 0 ];

% Generator Matrix IRREGULAR
% H = [  0 0 0 1 1 0 0 1 ;
%        1 1 1 0 0 1 0 0 ;
%        0 0 1 0 0 1 1 1 ;
%        1 0 0 1 1 0 1 0 ];


% Create LDPC_Soft
ldpc_s = ldpc_soft(H);

% check values
%{
ldpc_h.n
ldpc_h.m
ldpc_h.Wc
ldpc_h.c_nodes
ldpc_h.v_nodes
%}



% Message sent
X = [ 1 0 0 1 0 1 0 1 ]

% Message received
% Y = [ 1 1 0 1 0 1 0 1 ]

% Message received soft
Y = [ 0.8 0.6 0.2 0.8 0.2 0.7 0.1 0.9]

% check functions

% Init
ldpc_s_init = init(ldpc_s, Y);

% Decoder
ldpc_s_decoder = steps(ldpc_s_init);

c = ldpc_s_decoder.c_nodes;
v = ldpc_s_decoder.v_nodes;


% Decision
% Y_MAP = decode(ldpc_h, Y)
% 
 Y_Soft = decode(ldpc_s, Y)
 
