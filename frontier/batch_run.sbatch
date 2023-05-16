#!/bin/bash

#SBATCH -A CSC326
#SBATCH -J Ginkgo-Pele
#SBATCH -o %x-%j.out
#SBATCH -t 1:00:00
#SBATCH -p batch
#SBATCH -N 2

SOLVER=ginkgo_BICGSTAB NTASKS=16 NCELLS="128 256 256" MAX_GRID_SIZE=64 ./run-reacteval.sh 
