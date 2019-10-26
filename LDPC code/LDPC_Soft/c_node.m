classdef c_node
    %todo
    properties
        Wr
        links_to_Vnodes
        buffer
        tab_r0
        tab_r1
    end
    
    methods
        function obj=c_node(Wr, links)
            obj.Wr = Wr;
            obj.links_to_Vnodes = links;
            obj.buffer = [];
            obj.tab_r0 = [];
            obj.tab_r1 = [];
        end
    end
end

