# Simple automatic build script for FrontISTR

Open-Source Large-Scale Parallel FEM program for Nonlinear Structural Analysis : FrontISTR is distributed from [FrontISTR forum](http://www.multi.k.u-tokyo.ac.jp/FrontISTR/) under MIT license.

Development version is also available on [Github](https://github.com/FrontISTR/FrontISTR/).

This script (`fistr_build.sh`) support easy building and installation for FrontISTR.

This script is distributed under MIT license. Please see LICENSE.txt.

## Requiements

Please install following software in advance.

  - curl
  - git
  - cmake
  - openmpi
  - gcc/g++
  - gfortran

## Optional

  - Intel MKL
  - Intel MPI

## Usage

```
 % git clone https://github.com/michioga/fistr_build_script.git
 % cd fistr_build_script
 % sh fistr_build.sh
```

FrontISTR (fistr1, hec2rcap, hecmw_part1, hecmw_vis1, rconv, rmerge) will be installed under `$HOME/local/bin`.

## Edit script

If you like to increase make speed, edit `MAKE_PAR` variable in script.
Default value is `4`.

```
# START modify as needed.
BUILD_ROOT=`pwd`
LIB_ROOT=${BUILD_ROOT}/local
MAKE_PAR=4
COMPILER="GNU" # GNU  | GNUMKLIMPI | Intel | IntelOMPI
# END modify.
```

## Current supported platform

| name       | compiler         | MPI library | LaPACK library |
|------------|------------------|-------------|----------------|
| GNU        | gcc/g++/gfortran | OpenMPI     | OpenBLAS       |
| GNUMKLIMPI | gcc/g++/gfortran | Intel MPI   | Intel MKL      |
| Intel      | icc/icpc/ifort   | Intel MPI   | Intel MKL      |
| IntelOMPI  | icc/icpc/ifort   | OpenMPI     | Intel MKL      |

