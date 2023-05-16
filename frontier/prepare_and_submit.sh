#!/bin/bash

bf=submit.sbatch

set -x
set -e 

#declare -a SOLVERS=("magma_direct" "ginkgo_BICGSTAB" "ginkgo_GMRES")
#declare -a N_TASKS=("16" "32" "64" "128")
#declare -a N_TASKS=("1" "8" "64" "512" "4096")
#declare -a MAX_GRID_SIZE=("32" "64")
declare -a SOLVERS=("ginkgo_GMRES" "ginkgo_BICGSTAB" "magma_direct")
declare -a N_TASKS=("1" "8" "64" "512" "4096")
declare -a GRID_SIZE=("64")
base_size="64"

for s in "${SOLVERS[@]}"
do
	for nt in "${N_TASKS[@]}"
	do
		num_nodes=$(($nt/8))
		if [[ $num_nodes < 1 ]];
		then
			num_nodes=1
		fi
		for batch_size in "${GRID_SIZE[@]}"
		do
			echo "#!/bin/bash" > $bf
			echo "#SBATCH -A CSC326" >> $bf
			echo "#SBATCH -J Ginkgo-Pele-$s-$nt" >> $bf
			echo "#SBATCH -o %x-%j.out" >> $bf
			echo "#SBATCH -t 00:10:00" >> $bf
			echo "#SBATCH -p batch" >> $bf
			echo "#SBATCH -N $num_nodes" >> $bf
			mult=$(echo $nt | awk '{ print $1^(1/3) }')
			c_string=$(yes "$((${base_size} * $mult))" | head -3 | xargs echo)
			echo "SOLVER=$s NTASKS=$nt NCELLS=\"$c_string\" MAX_GRID_SIZE=$batch_size ./run-reacteval.sh" >> $bf
			sbatch $bf
		done
	done
done


