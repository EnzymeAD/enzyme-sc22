# enzyme-sc22
We have introduced a composable and generic LLVM-based mechanism to
differentiate a variety of parallel programming models. To illustrate
the composability of Enzyme’s differentiation of parallel frameworks, we
apply it to several distinct parallel variations of LULESH, and
miniBUDE. We evaluate LULESH variations that use MPI, OpenMP, hybrid
MPI+OpenMP, MPI.jl, and the RAJA portable parallel programming
framework, written in C++ and Julia. To further compare our performance
against current literature, we are comparing the automatic
differentiation performance to the CoDiPack-differentiated LULESH. Our
evaluation on miniBUDE was designed to validate our automatic
differentiation performance claims on LULESH on a second, distinct
application, as well as testing Enzyme’s ability to automatically
differentiate Julia’s shared-memory parallelism. We evaluate an OpenMP
version in C++, and a Julia-version utilizing tasks. To differentiate
both two Julia codes, we extend Enzyme.jl, Enzyme’s Julia bindings.
Because Enzyme is a tool that takes arbitrary existing code as LLVM IR
and computes the derivative (and gradient) of that function, LLVM is a
prerequisite for Enzyme. The particular LLVM built here enables turning
on/off OpenMP optimizations for an ablation analysis.

Evaluation of Enzyme upon these benchmarks allowed the paper to validate
our automatic differentiation performance claims of both efficiency and
scalability. As such, the original (referred to as the primal) and
differentiated versions of these benchmarks were evaluated on varying
thread counts and ranks, as well

#### Machine

Experiments were run on an AWS c6i.metal instance with hyper-threading
and Turbo Boost disabled, running Ubuntu 20.04 running on a dual-socket
Intel Xeon Platinum 8375C CPU at 2.9 GHz with 32 cores each and 256 GB
RAM.

#### Obtaining the code

All the codes and benchmarks are available on Github
<a href="github.com/EnzymeAD/enzyme-sc22"
class="uri">github.com/EnzymeAD/enzyme-sc22</a> at commit `ade41ef9`,
DOI [10.5281/zenodo.6609054](https://doi.org/10.5281/zenodo.6609054). We first obtain the code:
```console
cd $HOME
git clone --recursive https://github.com/EnzymeAD/enzyme-sc22
cd enzyme-sc22
git checkout 17c816a
```

This repository contains submodules for the benchmarks and codes listed
below.

<div id="tbl:code_details">

| Code        | Link                                               | Hash      |
|:------------|:---------------------------------------------------|:----------|
| BUDE        | [github.com/wsmoses/Enzyme-BUDE](github.com/wsmoses/Enzyme-BUDE)     | `f3cba59` |
| LULESH-CoDi | [github.com/wsmoses/CODI-LULESH](github.com/wsmoses/CODI-LULESH)      | `ad3e8fc` |
| LULESH-CPP  | [github.com/wsmoses/Enzyme-MPI](github.com/wsmoses/Enzyme-MPI)       | `bfb4ef8` |
| LULESH-RAJA | [github.com/wsmoses/LULESH-MPI-RAJA](github.com/wsmoses/LULESH-MPI-RAJA)  | `1375c61` |
| LULESH.jl   | [github.com/JuliaLabs/LULESH.jl](github.com/JuliaLabs/LULESH.jl)      | `3b8c862` |
| Enzyme      | [github.com/EnzymeAD/Enzyme](github.com/EnzymeAD/Enzyme)          | `5c89a86` |
| LLVM        | [github.com/jdoerfert/llvm-project](github.com/jdoerfert/llvm-project)   | `354c7f8` |

</div>

<span id="tbl:code_details" label="tbl:code_details"></span>

To evaluate the artifact, we offer four options.

1.  The first option is an AMI or Amazon Machine Image. An AMI is an
    image of the virtual machine which ran our experiements and can be
    used to create an identical virtual machine with the same operating
    system and existing builds of all experimental binaries and setups.
    For those who wish to precisely emulate our experimental
    methodology, create a new Virtual Machine on AWS (we used a
    c6i.metal instance) and search for the the ID of our provided image
    `ami-0d98fc05a03ebe550`. You may then launch the instance and then
    skip the rest of this section that involves downloading or building
    the experiments.

2.  The second option is to build the tools and experiments from source.
    This is the same procedure which was done to produce the AMI in the
    first option and is outlined below.

3.  The third option to download the build artifacts from CI. Every push
    to the benchmarks repository will automatically build, test, and
    upload all the benchmarks (see
    <https://github.com/EnzymeAD/enzyme-sc22/tree/main/.github/workflows>
    for the precise build commands). One can download the benchmarks
    built by CI by selecting the “Actions” tab, selecting the latest
    build of the corresponding benchmark, and clicking the binary below
    the “Artifacts” header. Like the AMI, one may then skip the rest of
    the section that involves downloading or building the experiments.
    Note that the binary is built on Ubuntu X86 and one will need a
    compatible system (e.g. not ARM, not macOS, to run the prebuilt
    binary from CI).

4.  The fourth option is to use a pre-built docker image
    (`wsmoses/enzymesc22`). The docker image can then be invoked with
    the following command:
```console
sudo docker run --privileged -it wsmoses/enzymesc22:latest /bin/bash
```
We begin by installing OpenMPI and Julia and build LLVM and Enzyme.

#### MPI

Our tests with MPI require OpenMPI which can be obtained in Ubuntu using
the following command.
```console
sudo apt-get install -y autoconf cmake gcc g++ gfortran ninja-build libopenmpi-dev numactl
```
#### Julia

The Lulesh.jl and miniBUDE.jl tests were run using Julia 1.7. Julia at
this version must be found in your path before being able to run the
Julia tests. To obtain a working Julia installation see
<https://julialang.org/downloads/> and follow the provided installation
instructions. You can add julia executable to the PATH variable using:
```console
export PATH=/home/ubuntu/julia-1.7.3/bin/:$PATH
```
#### llvm-project

We first need to build the LLVM compiler toolchain before we can
subsequently link the compiler plugin of Enzyme against our built LLVM
version. For our compiler toolchain we used a fork of LLVM 15 (main)
which enables OpenMPOpt to be completely disabled. To install LLVM,
please follow the following steps:
```console
cd $HOME/enzyme-sc22/llvm-project
mkdir build && cd build
cmake ../llvm -GNinja -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="llvm;clang;openmp" -DLLVM_TARGETS_TO_BUILD=X86
ninja
# This may take a while
# clang is now be available in llvm-project/build/bin/clang
```
#### Enzyme

We now must build Enzyme based off of our chosen LLVM version.
```console
cd $HOME/enzyme-sc22/Enzyme/enzyme
mkdir build
cd build
cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR=../../../llvm-project/build
ninja
# ClangEnzyme-15.so will now be available in Enzyme/enzyme/build/Enzyme/
```
To aid in the building of the benchmarks, it is necessary to setup two
environment variables.
```console
export ENZYME_PATH=$HOME/enzyme-sc22/Enzyme/enzyme/build/Enzyme/ClangEnzyme-15.so
export CLANG_PATH=$HOME/enzyme-sc22/llvm-project/build/bin
```
#### Disabling/Enabling Hyperthreading

To obtain reproducible results that are not subject to oddities
resulting from thread mapping, we recommend the disabling of
hyperthreading, if appropriate for the particular test case being run.
We have provided two scripts that can be easily edited for this purpose.
Note that these scripts assume the use of the same dual-socket 32-core
per CPU machine and can be modified to disable the appropriate cores for
a different machine. They can be run as follows:
```console
cd $HOME/enzyme-sc22
./disable.sh
```
or
```console
cd $HOME/enzyme-sc22
./enable.sh
```
#### Evaluation of Benchmarks

Once the preliminary setup is complete, we can now enter one of the test
directories, build, and run the corresponding benchmark.

We have created a Python3 scripts for running all the executables and
performing scaling analyses. The python scripts run the executables at
different MPI rank and OpenMP thread counts, corresponding to the
experiments we performed in the paper. If running on a machine of a
different size, these scripts can be edited to use the available number
of cores on your machine.

#### LULESH-CPP

The following commands can be used to build all the executables.
```console
cd $HOME/enzyme-sc22/LULESH-CPP
make -j
# Binaries available in enzyme-sc22/LULESH-CPP
# ser-single-forward.exe
# ser-single-gradient.exe
# omp-single-forward.exe
# omp-single-gradient.exe
# ompM-single-forward.exe
# ompM-single-gradient.exe
# ompOpt-single-forward.exe
# ompOpt-single-gradient.exe
```
To run the evaluation:
```console
cd $HOME/enzyme-sc22/LULESH-CPP/bench/
cd omp-mpi
./script.py
./res.py
# output of benchmark times in results.txt
cd ../omp-single
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ompOpt-single
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-strong-scaling
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-weak-scaling
./script.py
./res.py
# output of benchmark times in results.txt
```
#### LULESH-RAJA

The following commands can be used to build all the executables.
```console
cd $HOME/enzyme-sc22/LULESH-RAJA
mkdir build
cd build
cmake .. -G Ninja -DENABLE_OPENMP=ON -DLLVM_BUILD=$CLANG_PATH/.. -DENZYME=$ENZYME_PATH -DMPI_INCLUDE=/usr/lib/x86_64-linux-gnu/openmpi/include
ninja
# Binaries available in LULESH-RAJA/build/bin
# lulesh-v2.0-RAJA-seq.exe
# lulesh-v2.0-RAJA-seq-grad.exe
# lulesh-v2.0-RAJA-omp.exe
# lulesh-v2.0-RAJA-omp-gradient.exe
# lulesh-v2.0-RAJA-ompOpt.exe
# lulesh-v2.0-RAJA-ompOpt-gradient.exe
# lulesh-v2.0-RAJA-seq-mpi.exe
# lulesh-v2.0-RAJA-seq-mpi-grad.exe
```
To run the evaluation:
```console
cd $HOME/enzyme-sc22/LULESH-RAJA/bench
cd omp-mpi
./script.py
./res.py
# output of benchmark times in results.txt
cd ../omp-single
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ompOpt-single
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-strong-scaling
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-weak-scaling
./script.py
./res.py
# output of benchmark times in results.txt
```
#### LULESH.jl

You may then need to explicitly run various setup routines within
Julia’s package manager. To fix the Julia setup for the test, perform
the following to enter an interactive shell.
```console
cd $HOME/enzyme-sc22/LULESH.jl
julia --project -e "import Pkg; Pkg.instantiate()"
julia --project
    julia> import MPI
    julia> MPI.install_mpiexecjl(;destdir=".",force=true)
# The `mpiexecjl` executable should now
# exist in $HOME/enzyme-sc22/LULESH.jl
```
To run the evaluation:
```console
cd $HOME/enzyme-sc22/LULESH.jl/bench/
cd ser-mpi-strong-scaling
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-weak-scaling
./script.py
./res.py
# output of benchmark times in results.txt
```
#### LULESH-CoDiPack

The following commands can be used to build all the executables.
```console
cd $HOME/CODI-LULESH/lulesh-forward
make
# Binaries available in CODI-LULESH/lulesh-forward/
# lulesh2.0
cd CODI-LULESH/lulesh-gradient
make
# Binaries available in CODI-LULESH/lulesh-gradient/
# lulesh2.0
```
To run the evaluation:
```console
cd $HOME/CODI-LULESH/bench/
cd ser-mpi-strong-scaling
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ser-mpi-weak-scaling
./script.py
./res.py
```
#### BUDE

The following commands can be used to build all the executables.
```console
cd $HOME/enzyme-sc22/BUDE/openmp
make -j
# Binaries available in enzyme-sc22/BUDE/openmp
# ./ser-single-forward.exe
# ./ser-single-gradient.exe
# ./omp-single-forward.exe
# ./omp-single-gradient.exe
# ./ompOpt-single-forward.exe
# ./ompOpt-single-gradient.exe
```
We have created a Python3 script for running all the executables and
performing scaling analysis.
```console
cd $HOME/enzyme-sc22/BUDE/openmp/bench
cd omp-single
./script.py
./res.py
# output of benchmark times in results.txt
cd ../ompOpt-single
./script.py
./res.py
# output of benchmark times in results.txt
```
#### miniBUDE.jl

The following commands can be used to build all the executables.
```console
cd $HOME/enzyme-sc22/BUDE/miniBUDE.jl/
julia --project=Threaded -e "import Pkg; Pkg.instantiate()"
#No executables are created
```
We have created a Python3 script for running all the executables and
performing scaling analysis.
```console
cd $HOME/enzyme-sc22/BUDE/miniBUDE.jl/bench/
cd thread-strong-scaling
./script.py
./res.py
# output of benchmark times in results.txt
```
