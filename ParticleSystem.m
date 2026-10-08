classdef ParticleSystem < handle
    properties
        pos         % N x 2 bottom-left corners
        vel         % N x 2
        sz          % square side length
        hPatch
    end
    properties (Access = private)
        n
    end

    methods
        function obj = ParticleSystem(n, sz, speed, bounds, galaxy)
            if nargin < 5, galaxy = false; end
            obj.n = n;  obj.sz = sz;
            if galaxy
                obj.init_galaxy(speed, bounds, 23);
            else
                obj.init_random(speed, bounds);
            end
        end

        function init_random(obj, speed, b)
            % Uniform random positions, random velocity directions.
            lo = [b.x b.y];
            hi = lo + [b.w b.h] - obj.sz;
            obj.pos = lo + rand(obj.n, 2) .* (hi - lo);
            a = 2*pi*rand(obj.n, 1);
            obj.vel = speed * [cos(a) sin(a)];
        end

        function init_galaxy(obj, speed, b, R)
            % Spiral galaxy: dense core, trailing spiral arms, everything
            % orbiting counter-clockwise. `speed` is the orbital speed in the
            % outer disk.
            n = obj.n;  s = obj.sz;

            nArms     = 2;      % number of spiral arms
            twist     = 7;      % radians of spiral winding from core to rim
            armSpread = 0.35;   % angular scatter around each arm (radians)
            k         = 0.0001;      % radial concentration (higher = denser core)
            dispersion = 0.03;  % random velocity noise, fraction of speed

            ctr = [b.x + b.w/2, b.y + b.h/2];

            %  R   = min(b.w, b.h)/2 - s;
            maxR = min(b.w, b.h)/2 - s;
            if nargin < 4 || isempty(R), R = maxR; end
            R = min(R, maxR);                         % never spawn outside the bounds

            % Truncated exponential radial profile
            u = rand(n, 1);
            r = R * (-log(1 - u*(1 - exp(-k)))) / k;

            % Spiral arms (minus sign = trailing arms for counter-clockwise rotation)
            arm = randi(nArms, n, 1);
            th  = 2*pi*(arm - 1)/nArms - twist*(r/R) + armSpread*randn(n, 1);

            % pos stores bottom-left corners, so offset by half a square
            obj.pos = ctr - s/2 + r .* [cos(th) sin(th)];

            % Tangential velocity with a flat rotation curve. The r/sqrt(r^2+s^2)
            % factor matches the default softening in gravitateToCenter.
            vt = speed * r ./ sqrt(r.^2 + s^2);
            obj.vel = vt .* [-sin(th) cos(th)] + dispersion*speed*randn(n, 2);
        end

        function update(obj, dt)
            obj.vel = obj.vel * 0.9999;
            obj.pos = obj.pos + obj.vel * dt;
        end

        function bound(obj, b, restitution)
            if nargin < 3, restitution = 1; end
            lo = [b.x b.y];
            hi = lo + [b.w b.h] - obj.sz;
            below = obj.pos < lo;
            above = obj.pos > hi;
            obj.pos = min(max(obj.pos, lo), hi);
            obj.vel(below) =  abs(obj.vel(below)) * restitution;
            obj.vel(above) = -abs(obj.vel(above)) * restitution;
        end

        function gravitateToCenter(obj, dt, strength, opts)
            % Accelerate particles toward a center point (default: centroid).
            %   Target     [x y] point to attract toward (default: centroid of particles)
            %   Exponent   force falloff: a ~ 1/r^Exponent
            %                 0 = constant magnitude (original behaviour)
            %                 1 = 1/r, 2 = inverse-square (real gravity), -1 = linear spring
            %   Softening  length scale that removes the singularity at the center
            %   MaxAccel   clamp on acceleration magnitude
            %   Damping    velocity drag (1/s), lets the cluster settle instead of orbiting forever
            arguments
                obj
                dt (1,1) double
                strength (1,1) double
                opts.Target (1,2) double = [NaN NaN]
                opts.Exponent (1,1) double = 0
                opts.Softening (1,1) double = NaN
                opts.MaxAccel (1,1) double = Inf
                opts.Damping (1,1) double = 0
            end

            c = obj.pos + obj.sz/2;                          % true square centers
            if any(isnan(opts.Target))
                target = mean(c, 1);
            else
                target = opts.Target;
            end
            soft = opts.Softening;
            if isnan(soft), soft = obj.sz; end

            d  = target - c;                                 % N x 2
            r2 = sum(d.^2, 2) + soft^2;                      % softened, never zero
            acc = strength * d .* r2.^(-(opts.Exponent + 1)/2);

            if isfinite(opts.MaxAccel)                       % optional clamp
                a = sqrt(sum(acc.^2, 2));
                acc = acc .* min(1, opts.MaxAccel ./ max(a, realmin));
            end

            obj.vel = obj.vel + acc * dt;

            if opts.Damping > 0                              % exact exponential drag
                obj.vel = obj.vel * exp(-opts.Damping * dt);
            end
        end

        function h = draw(obj, ax, cmap, maxSpeed)
            % cmap:     N x 3 colormap (default turbo)
            % maxSpeed: speed that maps to the top of the colormap
            if nargin < 3 || isempty(cmap), cmap = turbo(256); end
            s = obj.speed();
            if nargin < 4 || isempty(maxSpeed), maxSpeed = 1.5*max(s); end

            faces = reshape(1:4*obj.n, 4, obj.n)';
            obj.hPatch = patch(ax, 'Faces', faces, 'Vertices', obj.verts(), ...
                            'FaceVertexCData', s, 'FaceColor', 'flat', ...
                            'EdgeColor', 'none');
            colormap(ax, cmap);
            ax.CLim = [0 maxSpeed];          % fixed limits so colors don't flicker
            h = obj.hPatch;
        end

        function render(obj)
            obj.hPatch.Vertices = obj.verts();
            obj.hPatch.FaceVertexCData = obj.speed();
        end
    end

    methods (Access = private)
        function s = speed(obj)
            s = sqrt(sum(obj.vel.^2, 2));    % N x 1, one value per square
        end
        function v = verts(obj)
            s = obj.sz;
            v = [reshape((obj.pos(:,1) + s*[0 1 1 0])', [], 1), ...
                 reshape((obj.pos(:,2) + s*[0 0 1 1])', [], 1)];
        end
    end
end