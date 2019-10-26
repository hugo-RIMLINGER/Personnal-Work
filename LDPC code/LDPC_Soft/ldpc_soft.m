classdef ldpc_soft
    % todo
    properties
        n
        m
        c_nodes
        v_nodes
        int=0
        stop =0
    end
    
    methods
        
        % Constructor
        function obj = ldpc_soft( matrix )
            
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
            %obj = cleanBuff(obj);
        end
        
        
        % Initialization
        function obj = init(obj, Y)
            % init
            for i=1:obj.n
                obj.v_nodes(i).Pi =Y(i);
                obj.v_nodes(i).q1 = repmat(Y(i),1,obj.v_nodes(i).Wc);
                obj.v_nodes(i).q0 = repmat(1-Y(i),1,obj.v_nodes(i).Wc);
            end
            %
        end
        
        
        % v_nodes -> c_nodes
        function obj = vNodes_to_cNodesBuff (obj)
            for i=1:obj.n
                %for j=1:obj.Wc
                for j=1:obj.v_nodes(i).Wc                   %MODIF                    
                    obj.c_nodes(obj.v_nodes(i).links_to_Cnodes(j)).buffer = [obj.c_nodes(obj.v_nodes(i).links_to_Cnodes(j)).buffer, obj.v_nodes(i).q1(j)];
                end
            end
        end
        
        
        % Parity Check
        function obj = parityCheck (obj)
            for i=1:obj.m % => for each c_node
                % proba calcul
                %for j=1:obj.Wr
                for j=1:obj.c_nodes(i).Wr                   %MODIF  
                    rest = obj.c_nodes(i).buffer;
                    rest(j) = []; % supprime la valeur qu'on ne doit pas utiliser dans les calculs
                    % calcul de r0
                    produit = 1;
                    for k=1:(obj.c_nodes(i).Wr)-1 
                        produit = produit * (1-(2*rest(k)));
                    end 
                    r0 = (1/2)+(1/2)*produit;
                    obj.c_nodes(i).tab_r0 = [ obj.c_nodes(i).tab_r0 r0 ];
                    obj.c_nodes(i).tab_r1 = [ obj.c_nodes(i).tab_r1 (1-r0) ];
                end
            end
        end
        
        
        % c_nodes -> v_nodes
        function obj = cNodes_to_vNodesBuff (obj)
            for i=1:obj.m % => for each c_node
                % send values
                for j=1:obj.c_nodes(i).Wr                   %MODIF
                    obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer_r0 = [ obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer_r0  obj.c_nodes(i).tab_r0(j) ];
                    obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer_r1 = [ obj.v_nodes(obj.c_nodes(i).links_to_Vnodes(j)).buffer_r1  obj.c_nodes(i).tab_r1(j) ];
                end
            end
        end
        
        
        % Majority Vote
        function obj = majorityVote (obj)
            K=1;
            for i=1:obj.n % => for each v_node
              
              %Calcul des valeurs q à transmettre
              for j=1:obj.v_nodes(i).Wc
                    produit_r0 = 1;
                    produit_r1 = 1;
                    rest = obj.v_nodes(i).buffer_r0;
                    rest1 = obj.v_nodes(i).buffer_r1;
                    rest(j) = []; 
                    rest1(j) = [];
                    for k=1:(obj.v_nodes(i).Wc)-1 
                        produit_r0 = produit_r0 *rest(k);
                        produit_r1 = produit_r1*rest1(k);
                    end 
                    K = 1/((1-obj.v_nodes(i).Pi)*produit_r0+(obj.v_nodes(i).Pi)*produit_r1);
                    obj.v_nodes(i).q0(j) = K*(1-obj.v_nodes(i).Pi)*produit_r0;
                    obj.v_nodes(i).q1(j) = K*(obj.v_nodes(i).Pi)*produit_r1;
              end
              
              %Calcul des Q
              produit_r0_tot = 1;
              produit_r1_tot = 1;
              
              for k=1:(obj.v_nodes(i).Wc)-1 
                        produit_r0_tot = (produit_r0_tot) * (obj.v_nodes(i).buffer_r0(k));
                        produit_r1_tot = (produit_r1_tot) * (obj.v_nodes(i).buffer_r1(k));
              end                
              obj.v_nodes(i).Q0= K*(1-(obj.v_nodes(i).Pi))*produit_r0_tot;
              obj.v_nodes(i).Q1= K*(obj.v_nodes(i).Pi)*produit_r1_tot;
              
              %mot code detecté
              if obj.v_nodes(i).Q0 > obj.v_nodes(i).Q1
                  obj.v_nodes(i).code=0;
              else
                  obj.v_nodes(i).code= 1;
              end
            end            
        end
        
        
        % Clean
        function obj = cleanBuff (obj)
            for i=1:obj.n
                obj.v_nodes(i).buffer_r0 = [];
                obj.v_nodes(i).buffer_r1 = [];
            end
            for i=1:obj.m
                obj.c_nodes(i).buffer = [];
            end
            obj.v_nodes(i).buffer_Q0 =0;
            obj.v_nodes(i).buffer_Q1 =0;
            
        end

        
        % Loop
        function obj = loop (obj)
            obj.int=0;
            Somme = 0;
            while (obj.int<20 && obj.stop==0)
                obj = steps(obj);
                Somme = 0;
                obj.int=obj.int+1;
                for i=1:obj.n
                    Somme = Somme + obj.v_nodes(i).code;
                end
                Somme
                if mod(Somme,2) == 0
                   
                    obj.stop = 1
                end 
            end    

        end
                
        % Decode
        function Y_MAP = decode (obj, Y)
            obj = init(obj, Y);
            obj = loop(obj);
            a = obj
            % Decision
            Y_MAP = zeros (1, obj.n);
            for i=1:obj.n
                Y_MAP(i) = obj.v_nodes(i).code;
            end
        end
        
        
    end
end


