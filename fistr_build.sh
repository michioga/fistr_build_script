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
get_openblas() {
  (git clone -b v0.2.20 https://github.com/xianyi/OpenBLAS.git) && (touch get_openblas_done)
}
build_openblas() {
  if [ -e get_openblas_done ]; then
    cd ${OPENBLAS_ARCHVIE}
    make -j${MAKE_PAR} CC=${CC} FC=${FC} DYNAMIC_ARCH=1 USE_OPENMP=1 NO_SHARED=1 BINARY=64
    make PREFIX=${LIB_ROOT} install
    cd ${BUILD_ROOT}
  else
    echo "No OpenBLAS archive."
  fi
}

########################################
# metis-5.1.0
########################################
get_metis() {
  curl ${CURL_FLAGS} -L -O http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
}
build_metis() {
  if [ -e metis-5.1.0.tar.gz ]; then
    tar xvf metis-5.1.0.tar.gz
    cd metis-5.1.0
    make config prefix=${LIB_ROOT} cc=${CC}
    make -j${MAKE_PAR}
    make install
    cd ${BUILD_ROOT}
  else
    echo "No METIS archive."
  fi
}

########################################
# scalapack-2.0.2
########################################
get_scalapack() {
  curl ${CURL_FLAGS} -L -O http://www.netlib.org/scalapack/scalapack-2.0.2.tgz
}
build_scalapack() {
  if [ -e scalapack-2.0.2.tgz ]; then
    tar xvf scalapack-2.0.2.tgz
    cd scalapack-2.0.2
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
    echo "No scalapack archive."
  fi
}

########################################
# MUMPS-5.1.2
########################################
get_mumps() {
  curl ${CURL_FLAGS} -L -O http://mumps.enseeiht.fr/MUMPS_5.1.2.tar.gz
}
build_mumps() {
  if [ -e MUMPS_5.1.2.tar.gz ]; then
    tar xvf MUMPS_5.1.2.tar.gz
    cd MUMPS_5.1.2
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
    echo "No MUMPS archive."
  fi
}

########################################
# Trilinos 12.12.1
########################################
get_trilinos() {
  (git clone -b trilinos-release-12-12-1 https://github.com/trilinos/Trilinos.git) && (touch get_trilinos_done)
}
build_trilinos() {
  if [ -e get_trilinos_done ]; then
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
  else
    echo "No Trilinos archive."
  fi
}

########################################
# REVOCAP_Refiner-1.1.04
########################################
get_refiner() {
  #curl -L -O http://www.multi.k.u-tokyo.ac.jp/FrontISTR/reservoir_f/link.pl?REVOCAP_Refiner-1.1.04.tar.gz
  echo "refiner"
}
build_refiner() {
  if [ -e REVOCAP_Refiner-1.1.04.tar.gz ]; then
    tar xvf REVOCAP_Refiner-1.1.04.tar.gz
    cd REVOCAP_Refiner-1.1.04
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
    echo "No REVOCAP_Refiner archvie."
  fi
}

########################################
# FrontISTR
########################################
get_fistr() {
  (git clone https://github.com/FrontISTR/FrontISTR.git) && (touch get_fistr_done)
}
build_fistr() {
  if [ -e get_fistr_done ]; then
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
  else
    echo "No FrontISTR archive."
  fi
}

########################################
# Main
########################################
mkdir -p ${LIB_ROOT}/bin ${LIB_ROOT}/lib ${LIB_ROOT}/include
export PATH=${LIB_ROOT}/bin:$PATH

set_compiler

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
