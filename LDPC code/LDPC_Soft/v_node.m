classdef v_node
    % todo
    properties
        Wc
        links_to_Cnodes
        buffer_r0
        buffer_r1
        q0
        q1
        Pi
        Q0
        Q1
        code
    end
    
    methods
        function obj = v_node(Wc, links)
            obj.Wc = Wc;
            obj.links_to_Cnodes = links;
            obj.buffer_r0 = [];
            obj.buffer_r1 = [];
            obj.q0 = [];
            obj.q1 = [];
            obj.Q0 = 0;
            obj.Q1 = 0;
        end
    end
    
end

