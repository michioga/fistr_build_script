# Simple automatic build script for FrontISTR

FrontISTR is opensource large-scale parallel FEM(Finit Element Method) program
for nonlinear structural analysis.

FrontISTR is distributed from [FrontISTR forum](http://www.multi.k.u-tokyo.ac.jp/FrontISTR/) under MIT license.

This script (`fistr_build.sh`) support easy building and installation for FrontISTR.

## Requiements

Please install following software in advance.

  - curl
  - git
  - cmake
  - openmpi
  - gfortran

## Usage

~~~
 % git clone https://github.com/michioga/fistr_build_script.git
 % cd fistr_build_script
 % sh fistr_build.sh
~~~

FrontISTR (fistr1, hec2rcap, hecmw_part1, hecmw_vis1, rconv, rmerge) will be installed under `$HOME/local/bin`.

