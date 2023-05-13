#!/bin/bash

bf=submit.sbatch

set -x
set -e 

#declare -a SOLVERS=("magma_direct" "ginkgo_BICGSTAB" "ginkgo_GMRES")
#declare -a N_TASKS=("16" "32" "64" "128")
#declare -a MAX_GRID_SIZE=("32" "64")
declare -a SOLVERS=("ginkgo_GMRES")
declare -a N_TASKS=("16")
declare -a GRID_SIZE=("32")

echo "#!/bin/bash" > $bf
echo "#SBATCH -A CSC326" >> $bf
echo "#SBATCH -J Ginkgo-Pele" >> $bf
echo "#SBATCH -o %x-%j.out" >> $bf
echo "#SBATCH -t 00:10:00" >> $bf
echo "#SBATCH -p batch" >> $bf


for s in "${SOLVERS[@]}"
do
	for nt in "${N_TASKS[@]}"
	do
		echo "#SBATCH -N $(($nt/8))" >> $bf
		for bsize in "${GRID_SIZE[@]}"
		do
			c_string="128 128 128"
			echo "SOLVER=$s NTASKS=$nt NCELLS=\"$c_string\" MAX_GRID_SIZE=$bsize ./run-reacteval.sh" >> $bf
		done
	done
done

