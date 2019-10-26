classdef ldpc_hard
    
    properties
        n
        m
        c_nodes
        v_nodes
        stop
        stable
        int
    end
    
    methods
        
        % Constructor
        function obj = ldpc_hard( matrix )
            
            % get n & m => matrix dimensions
            sz = size(matrix);
            m = sz(1);
            n = sz(2);
            obj.n = n;  %COLONNES
            obj.m = m;  %LIGNES
            
            % create c_nodes
            for i = 1:m                
                links = [];                
                for j = 1:n                    
                    if matrix(i,j) == 1
                        links = [links j];
                    end                        
                end
                Wr = sum(matrix(i, :)== 1);                  %MODIF
                c = c_node(Wr, links);
                obj.c_nodes = [obj.c_nodes c];
            end
            
            % create v_nodes
            matrix_transposed = transpose(matrix);
            for i = 1:n               
                links = [];
                for j = 1:m
                    if matrix_transposed(i,j) == 1
                        links = [links j];
                    end
                end
                Wc = sum(matrix(:, i)== 1);                  %MODIF
                v = v_node(Wc, links);
                obj.v_nodes = [obj.v_nodes v];
            end
                
        end
        
        
        % Steps
        function obj = steps(obj)    
            obj = vNodes_to_cNodesBuff(obj);
            obj = parityCheck(obj);
            obj = cNodes_to_vNodesBuff(obj);
            obj = majorityVote(obj);
            obj = cleanBuff(obj);
        end
        
        
        % Initialization
        function obj = init(obj, Y)
            % init
            for i=1:obj.n
                obj.v_nodes(i).value = Y(i);
            end
            %
        end
        
        
        % v_nodes -> c_nodes
        function obj = vNodes_to_cNodesBuff (obj)
            for i=1:obj.n
                %for j=1:obj.Wc
                for j=1:obj.v_nodes(i).Wc                   %MODIF                    
                    obj.c_nodes(obj.v_nodes(i).links_to_Cnodes(j)).buffer = [obj.c_nodes(obj.v_nodes(i).links_to_Cnodes(j)).buffer, obj.v_nodes(i).value];
                end
            end
        end
        
        
        % Parity Check
        function obj = parityCheck (obj)
            for i=1:obj.m % => for each c_node
                % parity check
                %for j=1:obj.Wr
                for j=1:obj.c_nodes(i).Wr                   %MODIF  
                    rest = obj.c_nodes(i).buffer;
                    rest(j) = [];
                    modulo = mod(sum(rest), 2);
                    if modulo == 0
                        obj.c_nodes(i).values = [ obj.c_nodes(i).values 0 ];
                    else
                        obj.c_nodes(i).values = [ obj.c_nodes(i).values 1 ];
                    end
                end
            end
        end
        
        
        % c_nodes -> v_nodes
        function obj = cNodes_to_vNodesBuff (obj)
            for i=1:obj.m % => for each c_node
                % send values
                for j=1:obj.c_nodes(i).Wr                   %MODIF
                    obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer = [ obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer  obj.c_nodes(i).values(j) ];
                end
            end
        end
        
        
        % Majority Vote
        function obj = majorityVote (obj)
            obj.stable=0;
            for i=1:obj.n % => for each v_node
                % majority vote
                total = [obj.v_nodes(i).buffer obj.v_nodes(i).value];
                number_of_ones = sum(total(:) == 1);
                number_of_zeros = sum(total(:) == 0);
                if number_of_ones > number_of_zeros
                    if obj.v_nodes(i).value == 1
                        obj.stable=obj.stable+1;
                    else
                        obj.v_nodes(i).value = 1;
                    end
                else % what if they are equal ????
                    if obj.v_nodes(i).value == 0
                        obj.stable=obj.stable+1;
                    else
                        obj.v_nodes(i).value = 0;
                    end
                end
            end
            if obj.stable==obj.n
                obj.stop=1;
            end            
        end
        
        
        % Clean
        function obj = cleanBuff (obj)
            for i=1:obj.n
                obj.v_nodes(i).buffer = [];
            end
            for i=1:obj.m
                obj.c_nodes(i).buffer = [];
            end
        end

        
        % Loop
        function obj = loop (obj)
            obj.stop=0;
            obj.int=0;
            while (obj.stop==0)||(obj.int>100)
                obj = steps(obj);
                obj.int=obj.int+1;
            end    
            fprintf("Nombre d'iterations : %d",obj.int)
        end
                
        % Decode
        function Y_MAP = decode (obj, Y)
            obj = init(obj, Y);
            obj = loop(obj);
            % Decision
            Y_MAP = zeros (1, obj.n);
            for i=1:obj.n
                Y_MAP(i) = obj.v_nodes(i).value;
            end
        end
        
        
    end
end

