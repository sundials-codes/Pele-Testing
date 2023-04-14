# please set your project account
export proj=csc317

# ---- required modules
module load cmake/3.23.2
# module load PrgEnv-cray           # use cray compiler environment
# module load PrgEnv-gnu            # use gnu compiler environment
module load PrgEnv-amd              # use amd compiler environment
module load craype-accel-amd-gfx90a # needed for GPU aware MPI
module load amd/5.4.3
module load cray-libsci/22.12.1.1
#module load cray-libsci/21.08.1.2   # the default module as of 12/22/22 is cray-libsci/22.06.1.3 and it causes Fortran linking errors in MAGMA

# ---- optional: faster builds
module load ccache
module load ninja

# ---- GPU-aware MPI
export MPICH_GPU_SUPPORT_ENABLED=1

# ---- AMReX and Pele specific settings

# optimize CUDA compilation for MI250X
export AMREX_AMD_ARCH=gfx90a

# ---- Paths to libraries
# export AMREX_HOME=${PWD}/AMReX
export GINKGO_DIR=${PWD}/INSTALL
export SUNDIALS_DIR=${PWD}/INSTALL
export SUNDIALS_LIB_DIR=$SUNDIALS_DIR/lib
export EXEC_PATH=/lustre/orion/$proj/proj-shared/Pele-sundials-frontier/ReactEval/bin
export LD_LIBRARY_PATH=${PWD}/INSTALL/lib:${PWD}/INSTALL/lib64/${LD_LIBRARY_PATH}
