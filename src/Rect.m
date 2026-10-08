classdef Rect < handle
    properties
        x
        y
        w
        h
    end

    properties (Access = private)
        
    end

    methods
        function obj = Rect(x, y, w, h)
            obj.x = x;
            obj.y = y;
            obj.w = w;
            obj.h = h;
        end

        function rect = getRect(obj)
            rect = [obj.x, obj.y, obj.w, obj.h];
        end

        function top_left = getTopLeft(obj)
            top_left = [obj.x, obj.y];
        end

        function center = getCenter(obj)
            center = [obj.x + obj.w/2, obj.y + obj.h/2];
        end

        function size = getSize(obj)
            size = [obj.w, obj.h];
        end

        function translate(obj, dx, dy)
            obj.x = obj.x + dx;
            obj.y = obj.y + dy;
        end

        function h = draw(obj, faceColor)
            if nargin < 2, faceColor = 'r'; end
            h = rectangle('Position', obj.getRect(), ...
                        'FaceColor', faceColor, 'EdgeColor', 'k', 'LineWidth', 2);
        end
        
    end

    methods (Access = private)
        
    end
end