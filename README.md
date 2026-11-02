# TTG - Theo's Terrain generator

It generates terrain

## Quick Start

Requirements: 
- git 
- zig (v0.17)

Linux (the only platform I have tested this on)

```shell
git clone git@github.com:TeeEnnEnn/ttg.git
cd ttg
zig build
./zig-out/bin/ttg <seed>
```

On my system (Ryzen 7600, arch linux) this takes 2s to run with a MAP_SIZE of 1000 and outputs a 3MB ppm and a 41MB PLY. 

## References 
I have used [Red Blob Games' "Making maps with noise functions"](https://www.redblobgames.com/maps/terrain-from-noise/) heavily throughout this implementation
I also used Perlin Noise for zig by [vExcess](https://github.com/vExcess/zig-perlin3d)

Thank you to Red Blob Games and vExcess.

### How I used AI for this

- ai was used to aid implementation - not take over. I used Opencode with GLM-5.3-Flash Free.
- It gave me the safe_seed() function
- It also wrote out the seed functions because I was too lazy to convert them from latex (which I got from desmos) to zig code
- It also give me the face mesh rendering code for the .ply file
