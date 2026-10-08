# Galaxy Particle Simulation

A real-time particle simulation in MATLAB that spawns thousands of square particles as a spiral galaxy and lets it evolve under a central gravitational pull. Particles are colored by speed, and a live readout shows FPS and per-frame timings.

| T = 0 | T = 500 | T = 2500 | T > 4000 |
|:---:|:---:|:---:|:---:|
| ![Galaxy stage 1](media/galaxy%201.png) | ![Galaxy stage 2](media/galaxy%202.png) | ![Galaxy stage 3](media/galaxy%203.png) | ![Galaxy stage 4](media/galaxy%204.png) |

*The galaxy developing over time, left to right.*

## Features

- **Two start configurations:** a uniform random scatter or a spiral galaxy with a dense core, trailing arms and counter-clockwise rotation
- **Configurable galaxy radius**
- **Softened central gravity** with selectable force falloff, acceleration clamp and velocity damping
- **Speed-based coloring** with a fixed colormap range, so colors stay stable between frames
- **Fully vectorized:** no per-particle loops, and all particles are drawn with a single `patch` object, which handles 10,000+ particles smoothly
- **Live HUD** with FPS, physics time, draw time and worst frame time

## Requirements

- MATLAB **R2020b or newer**
  - R2019b+ is needed for the `arguments` block in `gravitateToCenter`
  - R2020b+ is needed for the `turbo` colormap (use `parula` or `jet` on older versions)
- No toolboxes required

## Getting started

1. Clone the repository and open the project folder in MATLAB (or VS Code with the MATLAB extension).
2. Make sure `src/` is on your MATLAB path.
3. Run:

   ```matlab
   main
   ```

4. Press **Esc** or close the window to stop the simulation.

## Project structure

```
.
├── media/                 Screenshots used in this README
│   ├── galaxy 1.png
│   ├── galaxy 2.png
│   ├── galaxy 3.png
│   └── galaxy 4.png
├── src/
│   ├── main.m             Entry: setup, display config and the update loop
│   ├── ParticleSystem.m   Particle state, initialization, physics and rendering
│   ├── Particle.m
│   └── Rect.m             Rectangle helper used for the simulation bounds
├── .gitattributes
├── .gitignore
└── README.md
```

## Configuration

Settings are at the top of `src/main.m`:

| Variable | Meaning |
|---|---|
| `N` | Number of particles |
| `particle_size` | Side length of each square |
| `init_vel` | Initial speed (orbital speed in the outer disk for the galaxy) |
| `galaxy_radius` | Radius of the generated galaxy (clamped to fit inside the bounds) |
| `cmap` | Colormap used for speed coloring, e.g. `turbo(256)` |
| `maxSpeed` | Speed that maps to the top of the colormap |
| `bounds` | `Rect(x, y, w, h)` defining the simulation area |

Create a system with:

```matlab
bounds = Rect(0, 0, 100, 100);

% random start
ps = ParticleSystem(N, particle_size, init_vel, bounds);

% galaxy start, optional radius as the last argument
ps = ParticleSystem(N, particle_size, init_vel, bounds, true, 30);
```

### Gravity

The attraction is applied each frame in the update loop:

```matlab
ps.gravitateToCenter(dt, 8000, Exponent=2, Softening=2*ps.sz, MaxAccel=500);
```

| Option | Description |
|---|---|
| `Target` | `[x y]` point to attract toward (default: centroid of the particles) |
| `Exponent` | Force falloff, a ∝ 1/r^Exponent. `0` = constant, `1` = 1/r, `2` = inverse-square, `-1` = linear spring |
| `Softening` | Length scale that removes the singularity at the center |
| `MaxAccel` | Upper limit on acceleration magnitude |
| `Damping` | Velocity drag (1/s) so the cluster can settle instead of orbiting forever |

**Tip:** for a stable, roughly circular disk, use `Exponent=1` with strength `init_vel^2`. This gives a flat rotation curve that matches the galaxy's initial velocities. Inverse-square gravity gives more eccentric orbits and a more chaotic evolution.

## How it works

**Galaxy initialization** (`init_galaxy`)

1. Radii follow a truncated exponential profile, giving a dense core and sparse outskirts.
2. Each particle is assigned to one of the spiral arms, and its angle is offset by an amount that grows with radius (the twist), plus some random scatter.
3. Velocities are tangential, following a flat rotation curve, with a small random dispersion added.

**Simulation loop**

Each frame, `main.m` measures the elapsed time and clamps it to 50 ms for stability. It then:

1. Moves the particles: `update(dt)`
2. Accelerates them toward the center: `gravitateToCenter(dt, ...)`
3. Reflects them off the walls: `bound(bounds)`
4. Updates vertex positions and colors in the patch object: `render()`

## `ParticleSystem` API

| Method | Description |
|---|---|
| `ParticleSystem(n, sz, speed, bounds, galaxy, radius)` | Create the system. `galaxy` and `radius` are optional |
| `draw(ax, cmap, maxSpeed)` | Create the patch object on the given axes |
| `render()` | Push the current positions and speeds to the patch |
| `update(dt)` | Advance positions by `vel * dt` |
| `bound(rect, restitution)` | Clamp particles to the bounds and reflect their velocity |
| `gravitateToCenter(dt, strength, ...)` | Apply central gravity (see options above) |

## Limitations

- Particles are pulled toward a single center point and do not attract each other. It is not an N-body simulation, so the spiral arms shear and wind up over time from differential rotation instead of forming self-consistent structure.
- Integration is simple explicit Euler. Large time steps with strong forces can cause energy drift, so use `MaxAccel` and the frame-time clamp.

## Ideas for the future

- Mutual attraction using a Barnes-Hut tree or a grid-based approximation
- Mouse-controlled attractor using the `Target` option
- Color by distance from the center as an alternative to speed
- Recording frames to video