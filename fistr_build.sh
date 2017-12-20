#!/bin/sh
###################################################################
# Simple automatic build script for FrontISTR
###################################################################
# Copyright (c) 2017 Michio Ogawa
# This software is released under the MIT License, see LICENSE.txt
###################################################################

# Requirements
#  - curl
#  - git
#  - cmake
#  - openmpi
#
# Usage
#  sh fistr_build.sh
#
#  FrontISTR (fistr1, hec2rcap, hecmw_part1, hecmw_vis1, rconv, rmerge)
#  will be installed under $HOME/local/bin

# START modify as needed.
BUILD_ROOT=`pwd`
LIB_ROOT=${BUILD_ROOT}/local
MAKE_PAR=4
# compiler
CC=gcc
CXX=g++
FC=gfortran
MPICC=mpicc
MPICXX=mpicxx
MPIFC=mpif90
# END modify.

mkdir -p ${LIB_ROOT}/bin ${LIB_ROOT}/lib ${LIB_ROOT}/include
export PATH=${LIB_ROOT}/bin:$PATH

########################################
# OpenBLAS-0.2.20
########################################
get_openblas() {
  echo $(git clone -b v0.2.20 https://github.com/xianyi/OpenBLAS.git)
}
build_openblas() {
  cd OpenBLAS
  make -j${MAKE_PAR} DYNAMIC_ARCH=1 USE_OPENMP=1 NO_SHARED=1 BINARY=64
  make PREFIX=${LIB_ROOT} install
  cd ${BUILD_ROOT}
}

########################################
# metis-5.1.0
########################################
get_metis() {
  curl -L -O http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
}
build_metis() {
  tar xvf metis-5.1.0.tar.gz
  cd metis-5.1.0
  make config prefix=${LIB_ROOT} cc=${CC}
  make -j${MAKE_PAR}
  make install
  cd ${BUILD_ROOT}
}

########################################
# scalapack-2.0.2
########################################
get_scalapack() {
  curl -L -O http://www.netlib.org/scalapack/scalapack-2.0.2.tgz
}
build_scalapack() {
  tar xvf scalapack-2.0.2.tgz
  cd scalapack-2.0.2
  mkdir build
  cd build
  cmake \
    -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
    -DCMAKE_EXE_LINKER_FLAGS="-fopenmp" \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_Fortran_COMPILER=${FC} \
    -DBLAS_LIBRARIES=$LIB_ROOT/lib/libopenblas.a \
    -DLAPACK_LIBRARIES=$LIB_ROOT/lib/libopenblas.a \
    ..
  make -j${MAKE_PAR}
  make install
  cd ${BUILD_ROOT}
}

########################################
# MUMPS-5.1.2
########################################
get_mumps() {
  curl -L -O http://mumps.enseeiht.fr/MUMPS_5.1.2.tar.gz
}
build_mumps() {
  tar xvf MUMPS_5.1.2.tar.gz
  cd MUMPS_5.1.2
  cp Make.inc/Makefile.inc.generic Makefile.inc
  sed -i \
    -e "s|^#LMETISDIR = .*$|LMETISDIR = ${LIB_ROOT}|" \
    -e "s|^#IMETIS    = .*$|IMETIS = -I\$(LMETISDIR)/include|" \
    -e "s|^#LMETIS    = -L\$(LMETISDIR) -lmetis$|LMETIS = -L\$(LMETISDIR)/lib -lmetis|" \
    -e "s|^ORDERINGSF  = -Dpord$|ORDERINGSF = -Dpord -Dmetis|" \
    -e "s|^CC      = cc|CC      = mpicc|"  \
    -e "s|^FC      = f90|FC      = mpif90|"  \
    -e "s|^FL      = f90|FL      = mpif90|" \
    -e "s|^LAPACK = -llapack|LAPACK = -L${LIB_ROOT}/lib -lopenblas|" \
    -e "s|^SCALAP  = -lscalapack -lblacs|SCALAP  = -L${LIB_ROOT}/lib -lscalapack|" \
    -e "s|^LIBBLAS = -lblas|LIBBLAS = -L${LIB_ROOT}/lib -lopenblas|" \
    -e "s|^OPTF    = -O|OPTF    = -O -fopenmp|" \
    -e "s|^OPTC    = -O -I\.|OPTC    = -O -I. -fopenmp|" \
    -e "s|^OPTL    = -O|OPTL    = -O -fopenmp|" Makefile.inc
  make
  cp include/*.h ${LIB_ROOT}/include
  cp lib/*.a ${LIB_ROOT}/lib
  cd ${BUILD_ROOT}
}

########################################
# Trilinos 12.12.1
########################################
get_trilinos() {
  #curl -L -O http://trilinos.csbsju.edu/download/files/trilinos-12.12.1-Source.tar.bz2
  git clone -b trilinos-release-12-12-1 https://github.com/trilinos/Trilinos.git
}
build_trilinos() {
  #tar xvf trilinos-12.12.1-Source.tar.bz2
  #cd trilinos-12.12.1-Source
  cd Trilinos
  mkdir build
  cd build
  cmake \
    -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
    -DCMAKE_C_COMPILER=${MPICC} \
    -DCMAKE_CXX_COMPILER=${MPICXX} \
    -DCMAKE_Fortran_COMPILER=${MPIFC} \
    -DTPL_ENABLE_LAPACK=ON \
    -DTPL_ENABLE_SCALAPACK=ON \
    -DTPL_ENABLE_METIS=ON \
    -DTPL_ENABLE_MUMPS=ON \
    -DTrilinos_ENABLE_ML=ON \
    -DTrilinos_ENABLE_Zoltan=ON \
    -DTrilinos_ENABLE_OpenMP=ON \
    -DTrilinos_ENABLE_Amesos=ON \
    -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
    -DBLAS_LIBRARY_DIR=$LIB_ROOT/lib \
    -DLAPACK_LIBRARY_DIR=$LIB_ROOT/lib \
    -DBLAS_LIBRARY_NAMES="openblas" \
    -DLAPACK_LIBRARY_NAMES="openblas" \
    ..
  make -j${MAKE_PAR}
  make install
  cd ${BUILD_ROOT}
}

########################################
# REVOCAP_Refiner-1.1.04
########################################
get_refiner() {
  #curl -L -O http://www.multi.k.u-tokyo.ac.jp/FrontISTR/reservoir_f/link.pl?REVOCAP_Refiner-1.1.04.tar.gz
  echo "refiner"
}
build_refiner() {
  tar xvf REVOCAP_Refiner-1.1.04.tar.gz
  cd REVOCAP_Refiner-1.1.04
  make
  cp lib/x86_64-linux/libRcapRefiner.a ${LIB_ROOT}/lib
  cp Refiner/rcapRefiner.h ${LIB_ROOT}/include
  cd ${BUILD_ROOT}
}

########################################
# FrontISTR
########################################
get_fistr() {
  git clone https://github.com/FrontISTR/FrontISTR.git
}
build_fistr() {
  cd FrontISTR
  mkdir build; cd build
  cmake \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_CXX_COMPILER=${CXX} \
    -DCMAKE_Fortran_COMPILER=${FC} \
    -DBLAS_LIBRARIES=${LIB_ROOT}/lib/libopenblas.a \
    -DLAPACK_LIBRARIES=${LIB_ROOT}/lib/libopenblas.a \
    ..
  make -j${MAKE_PAR}
  make install
}

get_openblas &
get_metis &
get_refiner &
get_scalapack &
get_mumps &
get_trilinos &
get_fistr &
wait

build_openblas &
build_metis &
build_refiner &
wait
build_scalapack
build_mumps
build_trilinos
build_fistr
