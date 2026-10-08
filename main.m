disp("starting program")

% ---------------------------- Settings ----------------------------
particle_size = 0.4;
init_vel = 9;
cmap = turbo(256);   
maxSpeed = 25;          % speed that maps to the top of the colormap 
% ---------------------------- Init Particles ----------------------------
N = 10000;
bounds = Rect(0, 0, 100, 100);

ps = ParticleSystem(N, particle_size, init_vel, bounds, true);

figure; ax = axes; ax.Color = 'k';      % white particles are invisible on a white background
h = ps.draw(ax, cmap, maxSpeed);

% display config: delete the old `ax = ancestor(h,'axes')` line, keep the rest
disp("running simulation, close the window to stop");


% ---------------------------- Display config ----------------------------
fig = ancestor(ax, 'figure');
fig.Color = 'k';                         % figure background replaces the axes' black
fig.MenuBar = 'none'; fig.ToolBar = 'none';

fig.WindowStyle = 'normal';     % undock first, docked figures ignore Position
fig.Units = 'pixels';
fig.Position(3:4) = 700;        % 700x700 window, keeps its left/bottom
fig.Resize = 'off';             % optional: lock it square
ax.Toolbar.Visible = 'off';              % removes the "..." hover toolbar

axis(ax, 'off');                         % no ticks, labels, box or axes background

ax.Position = [0 0.12 1 0.88];           % was [0 0 1 1], leaves a 12% strip at the bottom

info = text(ax, 0.02, -0.01, '', 'Units', 'normalized', 'Color', [1 1 1]*0.7, ...
            'FontName', 'Consolas', 'FontSize', 11, ...
            'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

xlim(ax, [0 bounds.w]);
ylim(ax, [0 bounds.h]);

daspect(ax, [1 1 1]);        % 1 x-unit = 1 y-unit on screen
pbaspect(ax, [1 1 1]);       % plot box stays square, centred inside the axes position

% border
rectangle(ax, 'Position', bounds.getRect(), 'EdgeColor', 'w', 'LineWidth', 1.5);


% ---------------------------- Update Loop ----------------------------
simClock = tic;
prevTime = 0;
reportInterval = 0.5;                                  % seconds between readout updates
physicsSum = 0; drawSum = 0; elapsedSum = 0; frameCount = 0; worstFrame = 0;

while ishandle(h)
    now_ = toc(simClock);
    frameTime = now_ - prevTime;
    prevTime = now_;
    physicsDt = min(frameTime, 0.05);

    sectionTimer = tic;
    ps.update(physicsDt); 
    ps.gravitateToCenter(physicsDt, 1000, Exponent=2, Softening=2*ps.sz, MaxAccel=500);
    ps.bound(bounds); 
    ps.render();
    physicsSum = physicsSum + toc(sectionTimer);

    sectionTimer = tic;
    drawnow;
    if ~ishandle(h), break; end
    drawSum = drawSum + toc(sectionTimer);

    frameCount = frameCount + 1;
    elapsedSum = elapsedSum + frameTime;
    worstFrame = max(worstFrame, frameTime);

    if elapsedSum >= reportInterval
        info.String = sprintf('Particle simulation\nFPS: %.0f\nphys %.1f ms | draw %.1f ms | worst %.0f ms', ...
                              frameCount / elapsedSum, ...
                              1e3 * physicsSum / frameCount, ...
                              1e3 * drawSum / frameCount, ...
                              1e3 * worstFrame);
        physicsSum = 0; drawSum = 0; elapsedSum = 0; frameCount = 0; worstFrame = 0;
    end
    fig.KeyPressFcn = @closeOnEscape;
end

function closeOnEscape(src, event)
    if strcmp(event.Key, 'escape')
        close(src);
    end
end