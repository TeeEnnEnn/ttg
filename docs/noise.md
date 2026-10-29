# Noise

## What is noise

To creat e a smooth random pattern, we need to assign random values at a fixed position on a grid which is called a lattice. 
Then we need to blur these values using something equivalent to a gaussian blur - a smoothing function to blur the random values

Noise is a function that blurs random values generated on a grid (lattice).


## Advantages and Disadvantages of Noise

Advantages
- compact
- does not use a lot of memory when compared to texture mapping
- not complex to implement
- do not need paramtrization of the surface, which is required for texture mapping

Disadvantages
- slower than texture mapping

## Properties of Noise

1. Noise is **pseudorandom** and **deterministic**.

2. The noise function is **invariant**: it doesn't change under transformations.

3. The **dimension** of the point is given to the name of the noise. 1D, 2D and 3D noise functions take 1D, 2D, and 3D points as input parameters.  

4. Noise is **band limited** 

## Types of Noise 

1. White Noise

--- 
## References

1. [ScratchPixel](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/procedural-patterns-noise-part-1//introduction.html)
