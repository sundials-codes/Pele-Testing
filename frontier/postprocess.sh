#!/bin/bash -l

declare -a MECHS=("dodecane_lu_qss")
declare -a NTASKS=("1" "8" "64")
declare -a SOLVERS=("ginkgo_BICGSTAB" "ginkgo_GMRES" "magma_direct")


set -x
set -e


for m in "${MECHS[@]}"
do
	pushd $m
	for s in "${SOLVERS[@]}"
	do
	fname=${m}_${s}_scaling.csv
	echo "psize,bsize,ntasks,min,avg,max" > $fname
		for nt in "${NTASKS[@]}"
		do
			psize=$((64*64*64*$nt))
			bsize=$((64*64*64)) 
			out_time=$(awk '/^TinyProfiler/ {$1=""; print $0}' ReactEval.$s.64* | tr ' ' '\n' | perl -MScalar::Util -ne 'Scalar::Util::looks_like_number($_) && print' | tr '\n' ',')
			echo "$psize,$bsize,$nt,$out_time" >> $fname
		done
	done
	popd
done


#",64,$nt,$(find . -type f -name "ReactEval.$s.64.*.out" -exec sed -n '/^TinyProfiler/{n;/^TinyProfiler/q 1}' {} \;) >> $fname"
