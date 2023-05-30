#!/bin/bash

SOLVER="${SOLVER:=ginkgo_GMRES}" # GMRES, magma_direct, ginkgo_<GMRES|BICGSTAB>
MAX_GRID_SIZE="${MAX_GRID_SIZE:=64}"
INPUT_FROM_FILE="${INPUT_FROM_FILE:=0}"
SCALING="${SCALING:=1}" # 0 = none, 1 = setup scaling, 2 = solve scaling
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
# srun -n 1 --cpus-per-task=7 --gpus-per-task=1 --gpu-bind=closest \
srun -n 2 --cpus-per-task=7 --gpus-per-task=1 --gpu-bind=closest \
./Pele3d.hip.x86-trento.TPROF.MPI.HIP.ex.heptane_lu_88sk \
  inputs.3d-regt_GPU \
  chem_integrator=ReactorCvode \
  initFromFile=0 \
  initFile=/path/ \
  plotfile=plt \
  ncells=128 128 256 \
  max_grid_size=$MAX_GRID_SIZE \
  amrex.the_arena_is_managed=0 \
  cvode.solve_type=$SOLVER \
  cvode.max_order=4 \
  cvode.linear_solver_scaling=$SCALING \
  ode.reactor_type=2 \
  ode.dt=1.e-5 \
  ode.ndt=1 \
  ode.rtol=1.0e-6 \
  ode.atol=1.0e-5 \
  ode.use_typ_vals=1 \
ode.typ_vals= 7.27165946e-10 7.58044894e-08 6.120524396e-09 4.47556625e-05 2.214308438e-08 7.359964843e-07 3.971504515e-07 4.442275425e-09 3.016896333e-09 7.674393475e-07 1.121348327e-05 5.015279828e-08 1.882628991e-09 3.57410448e-07 4.361553463e-10 1.003599324e-08 1.326784937e-07 7.071454654e-10 3.30789621e-08 3.751288204e-10 2.175373937e-09 2.412600875e-09 1e-10 1e-10 1e-10 2.337837511e-10 5.374974987e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 2.604976721e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 0.0001371697768 2247.92073 \
  ode.verbose=2 | tee -a ReactEval.$SOLVER.$SCALING.$MAX_GRID_SIZE.$SLURM_JOB_ID.out

# # ---- when no typ_vals used
#   ode.rtol=1.0e-10 \
#   ode.atol=1.0e-12 \
#   ode.use_typ_vals=0 \

# # ---- drm19 typ_vals (21 species) when initFromFile=0
#   ode.rtol=1.0e-6 \
#   ode.atol=1.0e-5 \
#   ode.use_typ_vals=1 \
#   ode.typ_vals= 1.264395719e-07 3.439950337e-09 1.743039253e-08 4.476065801e-05 8.169749306e-08 1.962717878e-06 1.901755046e-07 6.293904149e-09 1.426610992e-09 9.645475288e-07 1.121538683e-05 1.236194683e-06 2.237763935e-08 2.178901525e-08 7.809437495e-07 7.129295508e-09 3.948299845e-07 1.741105547e-08 1.435373655e-08 0.0001371697768 1e-10 2305.877183 \

# # ---- dodecane_lu_qss (35 species) typ_vals when initFromFile=0
#   ode.rtol=1.0e-6 \
#   ode.atol=1.0e-5 \
#   ode.use_typ_vals=1 \
#   ode.typ_vals= 2.60930515e-10 2.497699961e-09 1.55974666e-08 6.52952975e-08 2.047750538e-07 8.074737062e-08 1.208521506e-06 2.903492347e-09 4.477368314e-05 1.047535694e-06 1.122171621e-05 6.670332503e-07 4.831131292e-07 4.842634744e-08 8.675129173e-09 2.522642639e-07 1.811206266e-08 6.788374995e-10 1.169394584e-09 1.318410816e-10 1e-10 1e-10 1.492187367e-09 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 3.492130067e-10 1e-10 1e-10 1e-10 1e-10 0.0001372037486 2259.516367 \

# # ---- dodecane_lu (53 species) typ_vals when initFromFile=0
#   ode.rtol=1.0e-6 \
#   ode.atol=1.0e-5 \
#   ode.use_typ_vals=1 \
#   ode.typ_vals= 1e-10 9.254136155e-09 4.179264473e-08 7.114535905e-08 5.142337976e-08 1.793762825e-08 2.349423213e-08 3.21782793e-10 4.476202222e-05 1.854338655e-10 6.184633495e-10 5.305696331e-07 1.121796845e-05 1e-10 2.305239634e-09 1.95794472e-09 3.022869547e-10 1e-10 1e-10 1e-10 1.361357044e-09 4.583025222e-09 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 0.0001371697768 2213.611026  \

# # ---- heptane_lu_88sk (88 species) typ_vals when initFromFile=0
#   ode.rtol=1.0e-6 \
#   ode.atol=1.0e-5 \
#   ode.use_typ_vals=1 \
# ode.typ_vals= 7.27165946e-10 7.58044894e-08 6.120524396e-09 4.47556625e-05 2.214308438e-08 7.359964843e-07 3.971504515e-07 4.442275425e-09 3.016896333e-09 7.674393475e-07 1.121348327e-05 5.015279828e-08 1.882628991e-09 3.57410448e-07 4.361553463e-10 1.003599324e-08 1.326784937e-07 7.071454654e-10 3.30789621e-08 3.751288204e-10 2.175373937e-09 2.412600875e-09 1e-10 1e-10 1e-10 2.337837511e-10 5.374974987e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 2.604976721e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 1e-10 0.0001371697768 2247.92073 \


date
