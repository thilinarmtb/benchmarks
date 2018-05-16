# Copyright (c) 2017, Lawrence Livermore National Security, LLC. Produced at
# the Lawrence Livermore National Laboratory. LLNL-CODE-734707. All Rights
# reserved. See files LICENSE and NOTICE for details.
#
# This file is part of CEED, a collection of benchmarks, miniapps, software
# libraries and APIs for efficient high-order finite element and spectral
# element discretizations for exascale applications. For more information and
# source code availability see http://github.com/ceed.
#
# The CEED research is supported by the Exascale Computing Project (17-SC-20-SC)
# a collaborative effort of two U.S. Department of Energy organizations (Office
# of Science and the National Nuclear Security Administration) responsible for
# the planning and preparation of a capable exascale ecosystem, including
# software, applications, hardware, advanced system engineering and early
# testbed platforms, in support of the nation's exascale computing imperative.

function setup_xlc()
{
   MPICC=mpixlc
   MPIC=mpixlc
   MPICXX=mpixlcxx
   MPIF77=mpixlf77
   mpi_info_flag="-qversion=verbose"

   # CFLAGS=""
   # CFLAGS="-O2 -qmaxmem=-1"
   # CFLAGS="-O3 -qstrict -qdebug=forcesqrt -qdebug=nsel -qmaxmem=-1"
   CFLAGS="-O3 -qnounwind -qsuppress=1540-1088:1540-1090:1540-1101"
   FFLAGS="-O3 -qnounwind"
   # TEST_EXTRA_CFLAGS=""
   TEST_EXTRA_CFLAGS="-O5 -qnounwind -qstrict"
   TEST_EXTRA_CFLAGS+=" -qsuppress=1540-1088:1540-1090:1540-1101"
   # TEST_EXTRA_CFLAGS+=" -qnoeh"
   # TEST_EXTRA_CFLAGS+=" -qreport -qlistopt -qlist -qskipsrc=hide -qsource"

   NEK5K_EXTRA_PPLIST="EXTBAR"
}


function setup_gcc()
{
   MPICC=mpicc
   MPIC=mpicc
   MPICXX=mpicxx
   MPIF77=mpif77

   CFLAGS="-O3 -mcpu=a2 -mtune=a2"
   FFLAGS="$CFLAGS"
   TEST_EXTRA_CFLAGS=""
   # TEST_EXTRA_CFLAGS+=" -std=c++11 -fdump-tree-optimized-blocks"

   NEK5K_EXTRA_PPLIST=""
}


function set_mpi_options()
{
   local account="${account:-CSC249ADCD04}"
   local partition="${partition:-default}"

   MPIEXEC_OPTS="-A ${account} -q ${partition} -t 60 "
   MPIEXEC_OPTS+=" --mode c$num_proc_node -n $num_nodes"
##   if [[ "$num_proc_node" -gt "16" ]]; then
##      MPIEXEC_OPTS+=" --overcommit"
##   fi
   compose_mpi_run_command
}


MFEM_EXTRA_CONFIG="MFEM_TIMER_TYPE=0"

valid_compilers="xlc gcc"
num_proc_build=${num_proc_build:-16}
num_proc_run=${num_proc_run:-16}
num_proc_node=${num_proc_node:-16}
num_nodes=$((num_proc_run/num_proc_node))
memory_per_node=16
node_virt_mem_lim=16

# Optional (default): MPIEXEC (mpirun), MPIEXEC_OPTS (), MPIEXEC_NP (-np)
MPIEXEC=qsub
MPIEXEC_NP=" --proccount"
