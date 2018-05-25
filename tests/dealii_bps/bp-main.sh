# Copyright (c) 2017, Lawrence Livermore National Security, LLC. Produced at
# the Lawrence Livermore National Laboratory. LLNL-CODE-734707. All Rights
# reserved. See files LICENSE and NOTICE for details.
#
# This file is part of CEED, a collection of benchmarks, miniapps, software
# libraries and APIs for efficient high-order finite element and spectral
# element discretizations for exascale applications. For more information and
# source code availability see http://github.com/ceed.
#
# The CEED research is supported by the Exascale Computing Project
# (17-SC-20-SC), a collaborative effort of two U.S. Department of Energy
# organizations (Office of Science and the National Nuclear Security
# Administration) responsible for the planning and preparation of a capable
# exascale ecosystem, including software, applications, hardware, advanced
# system engineering and early testbed platforms, in support of the nation's
# exascale computing imperative.


if [[ -z "$bp_test" ]]; then
   echo "This script (bp-main.sh) should not be called directly."
   echo "Use one of the bp*.sh scripts instead. Stop."
   return 1
fi

function build_and_run_tests()
{
   local bp_exe="$DEALII_CEED_BPS_DIR/$bp_test"

   if [[ ! -x "$bp_exe" ]]; then
      echo "Invalid test: $bp_exe. Stop."
      return 1
   fi

   set_mpi_options

   local p_min=1
   local p_max=16
   local jobcount=0
   local fname="dealii_bp-"`date '+%Y_%m_%d__%H_%M_%S'`.txt

   echo "Output file name is $fname"

   ## The value of detail should be 1 for the 
   ## actual benchmark runs
   local detail=1
   local qid_list=()

   echo " p |  q | n_elements |      n_dofs |     time/it |   dofs/s/it | CG_its | time/matvec" >> $fname

   for p in `seq $p_min 1 $p_max`; do
     local min_elem=1
     local max_elem=20
     local max_points=3000000
     while (( 2**min_elem < num_proc_node )); do
        ((min_elem=min_elem+1))
     done

     max_elem_order="$min_elem"
     local pp="$p" s=
     for ((s = min_elem; s <= max_elem; s++)); do
       local npts=$(( 2**s * (pp)**3 ))
       (( npts > max_points )) && break
       max_elem_order="$s"
     done
     max_elem=$max_elem_order

     local n=$num_nodes
     while (( n >= 2 )); do
        ((min_elem=min_elem+1))
        ((max_elem=max_elem+1))
        ((max_points=2*max_points))
        ((n=n/2))
     done

     # Make sure that we do not exceed 2^21 limit
     if [[ "$max_elem" -gt 20 ]]; then
       max_elem=20
     fi
     echo "Min elem: 2^ $min_elem, Max elem: 2^ $max_elem for p = $p"

     for m in `seq $min_elem 1 $max_elem`; do
       myjobs=$(qstat -u thilina | wc -l)
       while [ $myjobs -ge 10 ]; do
         echo 'Queue quota exceeded; sleeping for 10 seconds.'
         sleep 10
         myjobs=$(qstat -u thilina | wc -l)
       done 
  
       echo "Running $mpi_run $bp_exe $p $m $detail"

       qid=$($mpi_run $bp_exe $p $m $detail)
       qid_list+=("${qid}")
       jobcount=$((jobcount+1))
       sleep 10
     done
   done

   echo "Num jobs = $jobcount Jobs = ${qid_list[@]}"

   local count=0
   for ((count = 0; count < jobcount; count++)); do
       myjobs=$(qstat -u thilina)
       while [[ "${myjobs}" = *"${qid_list[${count}]}"* ]]; do
         myjobs=$(qstat -u thilina)
       done
       echo "$count"
       cat "${qid_list[${count}]}".output >> $fname
   done
}


test_required_packages="p4est-static dealii-static dealii-ceed-bps-static"
