# Pele-Testing

This repository holds scripts for building and running the [Pele suite of
codes](https://amrex-combustion.github.io/) for [SUNDIALS](https://github.com/LLNL/sundials) and
batched linear solver testing purposes.

## The ReactEval benchmark

The ReactEval benchmark program is based off of [the ReactEval test case described in the
documentation for
PelePhysics](https://amrex-combustion.github.io/PelePhysics/CvodeInPP.html#the-reacteval-c-test-case-with-cvode-in-details).
Currently the documentation for the test case is outdated when it comes to specifics, but it is
still good to read for background information. Here we describe how the ReactEval problem is used
for benchmarking time-integrators and linear solver algorithms/libraries.

In real Pele problems (from PeleC or PeleLM(eX)) they are solving chemically reacting flows by
coupling the Navier-Stokes equations (advection and diffusion) with chemical kinetics (reactions).
At a high-level, what Pele does is advance the physical processes indivdiually, couple them through
lagged source terms, and then use an iterative Spectral Deferred Corrections (SDC) scheme to refine
the solution. The reactions arise as ODEs per grid-cell of a block-structured adpative mesh
refinement (AMR) grid with the source term coming from the advection and diffusion.  

*The ReactEval program does the reactions advance only* from a given state. The ODEs per AMR cell that
ReactEval solves are

$$
\frac{dy_n}{dt} = \omega_{reac_n} + f_{ext}(adv+diffusion)_n 
$$

where $n$ is the number of species in the chemical mechanism being simulated. An additional ODE 
for the temperature is included as well, so there will be $n+1$ ODEs per grid cell.
In the default case, the initial state comes from a sinusoidal temperature profile. However, ReactEval can also begin from a
input file with states produced by PeleLM(eX). When starting from an input file, it is almost like
reaction advance done in a full Pele simulation where the source term is the initial state. This
feature is what makes ReactEval a good benchmark program for time-integration and linear solver
libraries targeting Pele problems. Characteristics like stiffness and conditioning will depend on
the input file. Different chemical mechanisms change the size of the ODE and linear systems per
grid-cell, and some of the AMR parameters allow control over things like the total number of linear
systems, and the number of batches and size of batches in a batched ODE solve. A ReactEval test case
can be setup using an input file as described in the docs from PelePhysics. The input parameters
which are most relevant to time-integration and linear solvers are:

* `ncells`: This will determine the total number of AMR grid cells in the domain, which plays a role
  in determining both the number of batches and the batch size.

* `max_grid_size`: `max_grid_size^3` yields the number of systems in a batch. It must be a power of 2
  and should be less than or equal to `ncells^3`. 

* `chem_integrator`: This sets which time-integrator to use. `ReactorCvode` is the most efficient
  in almost all cases. `ReactorCVode` uses the implicit CVODE integrator from SUNDIALS.
  Linear solvers are only interesting to test when `ReactorCvode` is used currently. Other integator options
  are `ReactorArkode` which uses the explicit Runge-Kutta methods in the ARKODE packages of SUNDIALS.

* `cvode.solver_type`: This sets which linear solver is to be used when the chemistry integrator is
  `ReactorCvode`. The current batched options are `magma_direct`, `ginkgo_GMRES`, `ginkgo_BICGSTAB`.
  The non-batched options are `GMRES` and `BCGS` (these are matrix-free implementations from
  SUNDIALS). Adding a linear solver requires implementing an interface to it in SUNDIALS. Contact
  [Cody Balos](mailto:balos1@llnl.gov) for more info. 

### Building and running

**On Frontier**

See [frontier/build-pele-frontier.sh](./frontier/build-pele-frontier.sh) for building.

See [frontier/run-reacteval.sh](./frontier/run-reacteval.sh) for running.

**On Crusher**

See [crusher/build-pele-crusher.sh](./crusher/build-pele-crusher.sh) for building.

See [crusher/run-reacteval.sh](./crusher/run-reacteval.sh) for running.

### Verifying runs

To verify a run for correctness, we first need to establish a baseline. Baseline runs should use the ReactEval inputs `cvode.solver_type = GMRES` and `chem_integator = ReactorCvode`. 
We will use the [AMReX fcompare script](https://amrex-codes.github.io/amrex/docs_html/Faq.html?highlight=fcompare#frequently-asked-questions) to verify correctness.
In order to use `fcompare` we will need to turn on plotting in the Pele runs. This is done by setting the ReactEval input `plotfile = /path/to/plot`. 
For the baseline you should do `plotfile = /path/to/plotReference` then plot files will be created with the `plotReference` name as the prefix.
For further runs you should change this filename to something else.
You will also need to build `fcompare`, which requires a GNU compiler. On Crusher or Frontier, you can `module load gcc/12.2.0` navigate to the `PeleC/Submodules/AMReX/Tools/Plotfile/` and run `make`. 
Then you can run `fcompare` like so:

```
fcompare pltReference00001 plt00001. 
```

### Pre-tested setups for ReactEval


### Additional parameters relevant to time-integration

