% the particle is a physics object which uses the rect class to represent its shape and position. It has a velocity and can be updated over time.
classdef Particle < handle
    properties
        rectObj  % an instance of the rect class representing the particle's shape and position
        velocity % a 2D vector representing the particle's velocity
        color   % the color of the particle for rendering
    end

    methods
        function obj = Particle(rectObj, vx, vy, color)
            % Alternative constructor that takes a rect object directly
            obj.rectObj = rectObj;           % use the provided rect object
            obj.velocity = [vx, vy];         % set the initial velocity
            obj.color = color;               % set the color for rendering
        end

        function update(obj, dt)
            % Update the particle's position based on its velocity and the time step dt
            dx = obj.velocity(1) * dt;
            dy = obj.velocity(2) * dt;
            obj.rectObj.translate(dx, dy);  % move the rect object
        end

        function h = draw(obj)
            % Draw the particle using its rect object and color
            h = obj.rectObj.draw(obj.color);
        end

        function boundRectangle(obj, bounding_rect, restitution)
            if nargin < 3, restitution = 1; end   % 1 = perfect bounce, <1 loses energy, 0 = stops dead

            b = bounding_rect.getRect();
            r = obj.rectObj;

            minX = b(1);  maxX = b(1) + b(3) - r.w;
            minY = b(2);  maxY = b(2) + b(4) - r.h;

            if r.x < minX
                r.x = minX;
                obj.velocity(1) =  abs(obj.velocity(1)) * restitution;
            elseif r.x > maxX
                r.x = maxX;
                obj.velocity(1) = -abs(obj.velocity(1)) * restitution;
            end

            if r.y < minY
                r.y = minY;
                obj.velocity(2) =  abs(obj.velocity(2)) * restitution;
            elseif r.y > maxY
                r.y = maxY;
                obj.velocity(2) = -abs(obj.velocity(2)) * restitution;
            end
        end
    end
end