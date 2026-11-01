# TTG - Theo's Terrain generator

It generates terrain

## References 
I have used [Red Blob Games' "Making maps with noise functions"](https://www.redblobgames.com/maps/terrain-from-noise/) heavily throughout this implementation
I also used Perlin Noise for zig by [vExcess](https://github.com/vExcess/zig-perlin3d)

Thank you to Red Blob Games and vExcess.

## Code Notes

### Seeds
These seeds were generated in desmos - I made functions that looked to give the most *"random-looking"* values. 

elevation seed: 
\frac{\cos\left(\sin\left(x\right)\right)^{-1}\ \cdot\sin\left(x\right)\cdot ex+123}{\tan\left(x^{3}-x^{2}\ -x\right)\left(\cos\left(x\right)\right)+23}

same formula without LaTeX:

```
        cos( sin(x) )^-1  *  sin(x)  *  e*x  + 123
-----------------------------------------------------
tan( x^3 - x^2 - x )  *  cos(x)  + 23
```


moisture seed

\frac{\cos\left(\tan\left(x\right)\right)^{-1}\ \cdot\tan\left(x\right)\cdot ex+123}{\sin\left(x^{3}-x^{2}\ -x\right)\left(\tan\left(x\right)\right)+23}

same formula without LaTeX:

```
        cos( tan(x) )^-1  *  tan(x)  *  e*x  + 123
-----------------------------------------------------
sin( x^3 - x^2 - x )  *  tan(x)  + 23
```

Notes:
- `x` is the world seed
- `e` is Euler's number (2.71828...)
- `cos( f(x) )^-1` is the reciprocal `1 / cos( f(x) )`, not arccos
- the seed is truncated to an integer and wrapped into `0..2^32-1`
  (negative values and non-finite results fold into a valid seed instead of crashing)


### How I used AI for this

- ai was used to aid implementation - not take over. I used Opencode with GLM-5.3-Flash Free.
- It gave me the safe_seed() function
- It also wrote out the seed functions because I was too lazy to convert them from latex (which I got from desmos) to zig code
- It also give me the face mesh rendering code for the .ply file
