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
COMPILER="GNU" # GNU | PGI | Intel
MKL=0 # If you have Intel MKL(not Free version), set 1.
# END modify.

# Misc. settings
CURL_FLAGS="-sS --connect-timeout 10 --max-time 120 --retry 2"

########################################
# Set compiler dependent option
########################################
set_compiler() {
  if [ $COMPILER = "PGI" ]; then
    CC=pgcc; CXX=pgc++; FC=pgfortran
    MPICC=mpicc; MPICXX=mpicxx; MPIFC=mpif90
    CFLAGS="-O2 -Minfo=all"; CXXFLAGS="-O2 -Minfo=all"; FCFLAGS="-O2 -Minfo=all"
    OMP="-mp"
  elif [ $COMPILER = "Intel" ]; then
    CC=icc; CXX=icpc; FC=ifort
    MPICC=mpiicc; MPICXX=mpiicpc; MPIFC=mpiifort
    CFLAGS="-O2 -report"; CXXFLAGS="-O2 -report"; FCFLAGS="-O2 -report"
    OMP="-qopenmp"
  else # default is GNU compiler
    CC=gcc; CXX=g++; FC=gfortran
    MPICC=mpicc; MPICXX=mpicxx; MPIFC=mpif90
    CFLAGS="-O -Wall"; CXXFLAGS="-O -Wall"; FCFLAGS="-O -Wall"
    OMP="-fopenmp"
  fi
}

########################################
# OpenBLAS-0.2.20
########################################
OPENBLAS="OpenBLAS"
get_openblas() {
  if [ ! -d ${OPENBLAS} ]; then
    git clone -b v0.2.20 https://github.com/xianyi/${OPENBLAS}.git
  else
    echo "Already downloaded ${OPENBLAS}"
  fi
}
build_openblas() {
  if [ -d ${OPENBLAS} ]; then
    cd ${OPENBLAS}
    make -j${MAKE_PAR} CC=${CC} FC=${FC} DYNAMIC_ARCH=1 USE_OPENMP=1 NO_SHARED=1 BINARY=64
    make PREFIX=${LIB_ROOT} install
    cd ${BUILD_ROOT}
  else
    echo "No ${OPENBLAS} archive."
  fi
}

########################################
# metis-5.1.0
########################################
METIS="metis-5.1.0"
get_metis() {
  if [ ! -f ${METIS}.tar.gz ]; then
    curl ${CURL_FLAGS} -L -O http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/${METIS}.tar.gz
  else
    echo "Already downloaded ${METIS}.tar.gz"
  fi
}
build_metis() {
  if [ -f ${METIS}.tar.gz ]; then
    tar xvf ${METIS}.tar.gz
    cd ${METIS}
    make config prefix=${LIB_ROOT} cc=${CC}
    make -j${MAKE_PAR}
    make install
    cd ${BUILD_ROOT}
  else
    echo "No ${METIS} archive"
  fi
}

########################################
# scalapack-2.0.2
########################################
SCALAPACK="scalapack-2.0.2"
get_scalapack() {
  if [ ! -f ${SCALAPACK}.tgz ]; then
    curl ${CURL_FLAGS} -L -O http://www.netlib.org/scalapack/${SCALAPACK}.tgz
  else
    echo "Already downloaded ${SCALAPACK}.tgz"
  fi
}
build_scalapack() {
  if [ -f ${SCALAPACK}.tgz ]; then
    tar xvf ${SCALAPACK}.tgz
    cd ${SCALAPACK}
    mkdir build
    cd build
    cmake \
      -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
      -DCMAKE_EXE_LINKER_FLAGS=${OMP} \
      -DCMAKE_C_COMPILER=${CC} \
      -DCMAKE_Fortran_COMPILER=${FC} \
      -DBLAS_LIBRARIES=$LIB_ROOT/lib/libopenblas.a \
      -DLAPACK_LIBRARIES=$LIB_ROOT/lib/libopenblas.a \
      ..
    make -j${MAKE_PAR}
    make install
    cd ${BUILD_ROOT}
  else
    echo "No ${SCALAPACK} archive"
  fi
}

########################################
# MUMPS-5.1.2
########################################
MUMPS="MUMPS_5.1.2"
get_mumps() {
  if [ ! -f ${MUMPS}.tar.gz ]; then
    curl ${CURL_FLAGS} -L -O http://mumps.enseeiht.fr/${MUMPS}.tar.gz
  else
    echo "Already downloaded ${MUMPS}.tar.gz"
  fi
}
build_mumps() {
  if [ -f ${MUMPS}.tar.gz ]; then
    tar xvf ${MUMPS}.tar.gz
    cd ${MUMPS}
    cp Make.inc/Makefile.inc.generic Makefile.inc
    sed -i \
      -e "s|^#LMETISDIR = .*$|LMETISDIR = ${LIB_ROOT}|" \
      -e "s|^#IMETIS    = .*$|IMETIS = -I\$(LMETISDIR)/include|" \
      -e "s|^#LMETIS    = -L\$(LMETISDIR) -lmetis$|LMETIS = -L\$(LMETISDIR)/lib -lmetis|" \
      -e "s|^ORDERINGSF  = -Dpord$|ORDERINGSF = -Dpord -Dmetis|" \
      -e "s|^CC      = cc|CC      = ${MPICC}|"  \
      -e "s|^FC      = f90|FC      = ${MPIFC}|"  \
      -e "s|^FL      = f90|FL      = ${MPIFC}|" \
      -e "s|^LAPACK = -llapack|LAPACK = -L${LIB_ROOT}/lib -lopenblas|" \
      -e "s|^SCALAP  = -lscalapack -lblacs|SCALAP  = -L${LIB_ROOT}/lib -lscalapack|" \
      -e "s|^LIBBLAS = -lblas|LIBBLAS = -L${LIB_ROOT}/lib -lopenblas|" \
      -e "s|^OPTF    = -O|OPTF    = -O ${OMP}|" \
      -e "s|^OPTC    = -O -I\.|OPTC    = -O -I. ${OMP}|" \
      -e "s|^OPTL    = -O|OPTL    = -O ${OMP}|" \
      Makefile.inc
    make
    cp include/*.h ${LIB_ROOT}/include
    cp lib/*.a ${LIB_ROOT}/lib
    cd ${BUILD_ROOT}
  else
    echo "No ${MUMPS} archive"
  fi
}

########################################
# Trilinos 12.12.1
########################################
TRILINOS="Trilinos"
get_trilinos() {
  if [ ! -d ${TRILINOS} ]; then
    git clone -b trilinos-release-12-12-1 https://github.com/trilinos/${TRILINOS}.git
  else
    echo "Already downloaded ${TRILINOS}"
  fi
}
build_trilinos() {
  if [ -d ${TRILINOS} ]; then
    cd ${TRILINOS}
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
  else
    echo "No ${TRILINOS} archive"
  fi
}

########################################
# REVOCAP_Refiner-1.1.04
########################################
REFINER="REVOCAP_Refiner-1.1.04"
get_refiner() {
  if [ ! -f ${REFINER}.tar.gz ]; then
    #curl -L -O http://www.multi.k.u-tokyo.ac.jp/FrontISTR/reservoir_f/link.pl?${REFINER}.tar.gz
    echo "refiner"
  else
    echo "Already downloaded ${REFINER}.tar.gz"
  fi
}
build_refiner() {
  if [ -f ${REFINER}.tar.gz ]; then
    tar xvf ${REFINER}.tar.gz
    cd ${REFINER}
    sed -i \
      -e "s|^CC = gcc|CC = ${CC}|" \
      -e "s|^CFLAGS = -O -Wall \$(DEBUGFLAG)|CFLAGS = ${CFLAGS}|" \
      -e "s|^CXX = g++|CXX = ${CXX}|" \
      -s "s|^CXXFLAGS = -O -Wall -fPIC \$(DEBUGFLAG)|CXXFLAGS = ${CXXFLAGS}|" \
      -e "s|^F90 = gfortran|F90 = ${FC}|" \
      -e "s|^FFLAGS = -Wall $(DEBUGFLAG)|FFLAGS = ${FCFLAGS}|" \
      -e "s|^LDSHARED = g++ -shared -s|LDSHARED = ${CXX} -shared -s|" \
      MakefileConfig.in
    make
    cp lib/x86_64-linux/libRcapRefiner.a ${LIB_ROOT}/lib
    cp Refiner/rcapRefiner.h ${LIB_ROOT}/include
    cd ${BUILD_ROOT}
  else
    echo "No ${REFINER} archvie"
  fi
}

########################################
# FrontISTR
########################################
FRONTISTR="FrontISTR"
get_fistr() {
  if [ ! -d ${FRONTISTR} ]; then
    git clone https://github.com/FrontISTR/${FRONTISTR}.git
  else
    echo "Already downloaded ${FRONTISTR}"
  fi
}
build_fistr() {
  if [ -d ${FRONTISTR} ]; then
    cd ${FRONTISTR}
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
  else
    echo "No ${FRONTISTR} archive"
  fi
}

########################################
# Main
########################################
mkdir -p ${LIB_ROOT}/bin ${LIB_ROOT}/lib ${LIB_ROOT}/include
export PATH=${LIB_ROOT}/bin:$PATH

set_compiler

if [ ${MKL} -eq 0 ]; then
  get_openblas &
  get_scalapack &
fi
get_metis &
get_refiner &
get_mumps &
get_trilinos &
get_fistr &
wait

if [ ${MKL} -eq 0 ]; then
  build_openblas &
fi
build_metis &
build_refiner &
wait

if [ ${MKL} -eq 0 ]; then
  build_scalapack
fi
build_mumps
build_trilinos
build_fistr
