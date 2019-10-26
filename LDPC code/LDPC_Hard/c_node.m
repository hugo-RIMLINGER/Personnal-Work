classdef c_node
    %todo
    properties
        Wr
        links_to_Vnodes
        buffer
        values
        
    end
    
    methods

	% Constructor
        function obj=c_node(Wr, links)
            obj.Wr = Wr;
            obj.links_to_Vnodes = links;
            obj.buffer = [];
        end

    end
end

