classdef v_node
    % todo
    properties
        Wc
        links_to_Cnodes
        buffer
        value
    end
    
    methods

	% Constructor
        function obj = v_node(Wc, links)
            obj.Wc = Wc;
            obj.links_to_Cnodes = links;
            obj.buffer = [];
        end

    end
    
end

