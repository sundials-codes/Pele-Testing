#!/bin/bash

# ---- Abort script on first error
set -e

# ---- Load environment
source pele.profile

# ---- Parse script args
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -j|--buildthreads)
      BT="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--case)
      # Which Pele problem to build:
      #  reacteval, pelec, or pelelmex
      CASE="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--fresh)
      # Should the Pele build stage be from scratch or not
      FRESH=TRUE
      shift # past argument
      ;;  
    -v|--verbose)
      VERBOSE=TRUE
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# ---- Default values
if [[ ! -z ${VERBOSE+x} ]]; then
  set -x
fi

if [[ -z "$BT" ]]; then
  buildthreads=8
else
  buildthreads=$BT
fi

if [[ -z "$CASE" ]]; then
  CASE="reacteval"
fi

# ---- Chemistry mechanism
# chem=drm19
# chem=dodecane_lu
chem=dodecane_lu_qss

# ---- MAGMA install
magma_enable=TRUE
magma_source=magma
magma_install=${PWD}/INSTALL
if [[ ! -d $magma_source ]]; then
  wget http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.7.0.tar.gz
  tar -xvzf magma-2.7.0.tar.gz
  mv magma-2.7.0 magma
fi
if [[ ! -f $magma_install/lib/libmagma.so ]]; then
  cmake -S ${magma_source} -B ${magma_source}/builddir \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${magma_install} \
      -DCMAKE_CXX_COMPILER=hipcc \
      -DLAPACK_LIBRARIES=${CRAY_LIBSCI_PREFIX_DIR}/lib/libsci_amd.so \
      -DBUILD_SHARED_LIBS=ON \
      -DUSE_FORTRAN=OFF \
      -DMAGMA_ENABLE_HIP=ON \
      -DGPU_TARGET=gfx90a
  cd ${magma_source}/builddir
  make -j$buildthreads
  make install
  cd -
fi

# ---- Ginkgo install
ginkgo_enable=TRUE
ginkgo_source=ginkgo
ginkgo_install=$GINKGO_DIR
if [[ ! -d $ginkgo_source ]]; then
  git clone https://github.com/ginkgo-project/ginkgo
  cd ginkgo
  git checkout batch-develop
  cd -
fi
if [[ ! -f $ginkgo_install/lib/libginkgo.so ]]; then
  cmake -S ${ginkgo_source} -B ${ginkgo_source}/builddir \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo  -DAMDGPU_TARGETS=gfx90a \
    -DGINKGO_BUILD_HIP=ON -DGINKGO_BUILD_OMP=OFF -DGINKGO_BUILD_MPI=OFF \
    -DGINKGO_BUILD_BENCHMARKS=OFF -DGINKGO_BUILD_EXAMPLES=OFF -DGINKGO_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=$ginkgo_install -DCMAKE_INSTALL_LIBDIR=lib
  cd $ginkgo_source/builddir
  make -j$buildthreads VERBOSE=1 install
  cd -
fi

# ---- SUNDIALS install
sundials_source=sundials
if [[ ! -d $sundials_source ]]; then
  # git clone ssh://git@github.com/LLNL/sundials.git $sundials_source
  git clone https://github.com/LLNL/sundials.git $sundials_source
  cd sundials
  git checkout feature/ginkgo-batched
  cd -
fi
sundials_install=$SUNDIALS_DIR
sundials_lib_dir=$SUNDIALS_LIB_DIR
if [[ ! -f $sundials_lib_dir/libsundials_cvode.so ]]; then
  cmake -S $sundials_source -B $sundials_source/builddir \
    -DCMAKE_C_COMPILER=hipcc -DCMAKE_CXX_COMPILER=hipcc -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBS=OFF \
    -DENABLE_HIP=ON -DAMDGPU_TARGETS=gfx90a \
    -DENABLE_MAGMA=$magma_enable -DMAGMA_DIR=$magma_install -DSUNDIALS_MAGMA_BACKENDS=HIP \
    -DENABLE_GINKGO=$ginkgo_enable -DGinkgo_DIR=$ginkgo_install -DSUNDIALS_GINKGO_BACKENDS="HIP" \
    -DSUNDIALS_INDEX_SIZE=32 -DSUNDIALS_BUILD_WITH_PROFILING=ON -DSUNDIALS_LOGGING_LEVEL=1 \
    -DCMAKE_INSTALL_PREFIX=$sundials_install -DEXAMPLES_INSTALL=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib
  cd $sundials_source/builddir
  make -j$buildthreads VERBOSE=1 install
  cd -
fi

# if [[ ! -d AMReX ]]; then
#   git clone --recursive https://github.com/AMReX-Codes/AMReX.git
# fi

# if [[ ! -d AMReX-Hydro ]]; then
#   git clone --recursive https://github.com/AMReX-Codes/AMReX-Hydro.git
# fi

if [[ ! -d PelePhysics ]]; then
  #git clone --recursive https://github.com:AMReX-Combustion/PelePhysics.git
  git clone --recursive git@github.com:sundials-codes/PelePhysics.git
  cd PelePhysics
  git checkout feature/gptune-parameters-rebased
  cd -
fi

if [[ ! -d PeleC ]]; then
  git clone --recursive https://github.com/AMReX-Combustion/PeleC.git
  #git clone --recursive ssh://git@github.com:sundials-codes/PeleC.git
fi

if [[ ! -d PeleLMeX ]]; then
  git clone --recursive https://github.com/AMReX-Combustion/PeleLMeX.git
  #git clone --recursive ssh://git@github.com:sundials-codes/PeleLMeX.git
fi

if [[ "$CASE" == "pelec" ]]; then
  # -------- PeleC
  echo '!!!!!!!!!!!!!! Building PeleC ChallengeProblem '
  amrex_dir=${PWD}/PeleC/Submodules/AMReX
  amrex_hydro_dir=${PWD}/PeleC/Submodules/AMReX-Hydro
  pelephysics_dir=${PWD}/PelePhysics
  # pelephysics_dir=${PWD}/PeleC/Submodules/PelePhysics
  cd PeleC/Exec/Production/ChallengeProblem
  # cd PeleC/Exec/RegTests/PMF
  if [[ ! -z ${FRESH+x} ]]; then
    make \
          CXXSTD=c++17 \
          AMREX_HOME=${amrex_dir} \
          AMREX_HYDRO_HOME=${amrex_hydro_dir} \
          PELE_PHYSICS_HOME=${pelephysics_dir} \
          SUNDIALS_LIB_DIR=${sundials_lib_dir} \
          USE_HIP=TRUE \
          USE_MPI=TRUE \
          TINY_PROFILE=TRUE \
          PELE_USE_MAGMA=${magma_enable} \
          PELE_COMPILE_AJACOBIAN=TRUE \
          MAGMA_DIR=${magma_install} \
          PELE_USE_GINKGO=${ginkgo_enable} \
          GINKGO_DIR=${ginkgo_install} \
          Chemistry_Model=${chem} \
          DIM=3 \
          realclean
  fi
  make -j$buildthreads \
        VERBOSE=1 \
        CXXSTD=c++17 \
        AMREX_HOME=${amrex_dir} \
        AMREX_HYDRO_HOME=${amrex_hydro_dir} \
        PELE_PHYSICS_HOME=${pelephysics_dir} \
        SUNDIALS_LIB_DIR=${sundials_lib_dir} \
        USE_HIP=TRUE \
        USE_MPI=TRUE \
        TINY_PROFILE=TRUE \
        PELE_USE_MAGMA=${magma_enable} \
        PELE_COMPILE_AJACOBIAN=TRUE \
        MAGMA_DIR=${magma_install} \
        PELE_USE_GINKGO=${ginkgo_enable} \
        GINKGO_DIR=${ginkgo_install} \
        DIM=3 \
        Chemistry_Model=${chem}
elif [[ "$CASE" == "pelelmex" ]]; then
  # -------- PeleLMeX
  echo '!!!!!!!!!!!!!! Building PeleLMeX NormalJet_OpenDomain '
  # ---- PelePhysics and AMReX install
  amrex_dir=${PWD}/PeleLMeX/Submodules/amrex
  amrex_hydro_dir=${PWD}/PeleLMeX/Submodules/AMReX-Hydro
  # pelephysics_dir=${PWD}/PelePhysics
  pelephysics_dir=${PWD}/PeleLMeX/Submodules/PelePhysics
  cd PeleLMeX/Exec/Cases/NormalJet_OpenDomain
  # cd PeleLMeX/Exec/RegTests/FlameSheet
  if [[ ! -z ${FRESH+x} ]]; then
    make \
          CXXSTD=c++17 \
          AMREX_HOME=${amrex_dir} \
          AMREX_HYDRO_HOME=${amrex_hydro_dir} \
          PELE_PHYSICS_HOME=${pelephysics_dir} \
          SUNDIALS_LIB_DIR=${sundials_lib_dir} \
          USE_HIP=TRUE \
          USE_MPI=TRUE \
          TINY_PROFILE=TRUE \
          PELE_USE_MAGMA=${magma_enable} \
          PELE_COMPILE_AJACOBIAN=TRUE \
          MAGMA_DIR=${magma_install} \
          PELE_USE_GINKGO=${ginkgo_enable} \
          GINKGO_DIR=${ginkgo_install} \
          Chemistry_Model=${chem} \
          DIM=3 \
          realclean
  fi
  make -j$buildthreads \
        VERBOSE=1 \
        CXXSTD=c++17 \
        AMREX_HOME=${amrex_dir} \
        AMREX_HYDRO_HOME=${amrex_hydro_dir} \
        PELE_PHYSICS_HOME=${pelephysics_dir} \
        SUNDIALS_LIB_DIR=${sundials_lib_dir} \
        USE_HIP=TRUE \
        USE_MPI=TRUE \
        TINY_PROFILE=TRUE \
        PELE_USE_MAGMA=${magma_enable} \
        PELE_COMPILE_AJACOBIAN=TRUE \
        MAGMA_DIR=${magma_install} \
        PELE_USE_GINKGO=${ginkgo_enable} \
        GINKGO_DIR=${ginkgo_install} \
        DIM=3 \
        Chemistry_Model=${chem}
elif [[ "$CASE" == "reacteval" ]]; then
  # ------ Reacteval
  echo '!!!!!!!!!!!!!! Building ReactEval '
  amrex_dir=${PWD}/PeleC/Submodules/AMReX
  amrex_hydro_dir=${PWD}/PeleC/Submodules/AMReX-Hydro
  # pelephysics_dir=${PWD}/PelePhysics
  pelephysics_dir=${PWD}/PeleC/Submodules/PelePhysics
  cd PelePhysics/Testing/Exec/ReactEval/
  if [[ ! -z ${FRESH+x} ]]; then
    make \
          CXXSTD=c++17 \
          AMREX_HOME=${amrex_dir} \
          AMREX_HYDRO_HOME=${amrex_hydro_dir} \
          PELE_PHYSICS_HOME=${pelephysics_dir} \
          SUNDIALS_LIB_DIR=${sundials_lib_dir} \
          USE_HIP=TRUE \
          USE_MPI=TRUE \
          TINY_PROFILE=TRUE \
          PELE_USE_MAGMA=${magma_enable} \
          PELE_COMPILE_AJACOBIAN=TRUE \
          MAGMA_DIR=${magma_install} \
          PELE_USE_GINKGO=${ginkgo_enable} \
          GINKGO_DIR=${ginkgo_install} \
          Chemistry_Model=${chem} \
          DIM=3 \
          realclean
  fi
  make -j$buildthreads \
        VERBOSE=1 \
        CXXSTD=c++17 \
        AMREX_HOME=${amrex_dir} \
        AMREX_HYDRO_HOME=${amrex_hydro_dir} \
        PELE_PHYSICS_HOME=${pelephysics_dir} \
        SUNDIALS_LIB_DIR=${sundials_lib_dir} \
        USE_HIP=TRUE \
        USE_MPI=TRUE \
        TINY_PROFILE=TRUE \
        PELE_USE_MAGMA=${magma_enable} \
        PELE_COMPILE_AJACOBIAN=TRUE \
        MAGMA_DIR=${magma_install} \
        PELE_USE_GINKGO=${ginkgo_enable} \
        GINKGO_DIR=${ginkgo_install} \
        DIM=3 \
        Chemistry_Model=${chem}
else
  echo "Unknown value for case: $CASE"
  echo "  options are: pelec, pelelmex, reacteval"
  exit 1
fi
