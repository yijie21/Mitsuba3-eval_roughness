# Mitsuba3-eval_roughness

For some research reason, I wanted to evaluate roughness of the bsdf. However, eval_roughness is not supported for every bsdf in the original Mitsuba3. So I created a eval_roughness function for each bsdf, and if roughness is not a intrinsic property of a bsdf (e.g. dielectric), the roughness will always return 0.

## Compile and Usage

1. Compile: just follow the instructions on the official website.

   https://mitsuba.readthedocs.io/en/stable/src/developer_guide/compiling.html

2. Usage: after compilation, just add these lines in a python script for use

   ```python
   import sys
   sys.path.append('MITSUBA_PATH/build/python')
   import drjit as dr
   import mitsuba as mi
   
   # suppose we get a surface interaction si
   bsdf = si.bsdf()
   roughness = bsdf.eval_roughness(si. si.is_valid())
   ```