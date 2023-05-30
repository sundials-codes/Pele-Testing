#!/bin/bash

SOLVER="${SOLVER:=GMRES}" # GMRES, magma_direct, ginkgo_<GMRES|BICGSTAB>
MAX_GRID_SIZE="${MAX_GRID_SIZE:=32}"
INPUT_FROM_FILE="${INPUT_FROM_FILE:=0}"
SCALING="${INPUT_FROM_FILE:=0}" # 0 = none, 1 = setup scaling, 2 = solve scaling
INIT_FILE="${INIT_FILE:=/path/}"
SLURM_JOB_ID="${SLURM_JOB_ID:=0}"

# Abort script at first error
set -e

# Print each command to stdout before executing it
set -x

# Move to the test directory
cd $EXEC_PATH

date
# valgrind --tool=memcheck --leak-check=full --undef-value-errors=no \
srun -n 16 --cpus-per-task=7 --gpus-per-task=1 --gpu-bind=closest \
./PeleLMeX3d.hip.x86-trento.TPROF.MPI.HIP.ex \
  input.3d-KPP2 \
  chem_integrator=ReactorCvode \
  ic.input_name="/lustre/orion/world-shared/csc317/PeleLMeX/hit_ic_ut_128.in" \
  amrex.plot_file=pltLMeX \
  amr.plot_per_exact=0 \
  amr.check_int=50 \
  amr.n_cell=512 512 128 \
  amr.max_step=50 \
  amr.dt_shrink=0.01 \
  amr.stop_time=1.0 \
  amr.max_grid_size=$MAX_GRID_SIZE \
  cvode.solve_type=$SOLVER \
  cvode.linear_solver_scaling=$SCALING \
  ode.rtol=1.0e-6 \
  ode.atol=1.0e-5 \
  ode.verbose=2 | tee -a PeleLMeX.Challenge.$SOLVER.$SCALING.$MAX_GRID_SIZE.$SLURM_JOB_ID.out

date
