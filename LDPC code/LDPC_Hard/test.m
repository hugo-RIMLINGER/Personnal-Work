% test

% Generator Matrix REGULAR
H = [  0 1 0 1 1 0 0 1 ;
       1 1 1 0 0 1 0 0 ;
       0 0 1 0 0 1 1 1 ;
       1 0 0 1 1 0 1 0 ];

% Generator Matrix IRREGULAR
%{
H = [  0 0 0 1 1 0 0 1 ;
       1 1 1 0 0 1 0 0 ;
       0 0 1 0 0 1 1 1 ;
       1 0 0 1 1 0 1 0 ];
%}

   
% Create LDPC_Hard
ldpc_h = ldpc_hard(H);

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
Y = [ 1 1 0 1 0 1 0 1 ]

% check functions
%{
% Init
ldpc_h_init = init(ldpc_h, Y);

% Decoder
ldpc_h_decoder = steps(ldpc_h_init);

c = ldpc_h_decoder.c_nodes;
v = ldpc_h_decoder.v_nodes;
%}

% Decision
Y_MAP = decode(ldpc_h, Y)

