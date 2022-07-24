FROM ubuntu:focal
SHELL ["/bin/bash", "-c"]

RUN groupadd -r myuser && useradd -r -g myuser myuser

RUN apt-get update
RUN apt-get -y install apt-utils
RUN apt-get -y install tzdata --assume-yes
RUN apt-get -y install autoconf cmake gcc g++ gfortran ninja-build libopenmpi-dev
RUN apt-get -y install git 
RUN apt-get -y install wget
RUN apt-get -y install numactl
RUN apt-get -y install python3
RUN apt-get -y install time
RUN apt-get -y install libomp-dev
 
CMD ["echo", "Enzyme SC 22 Docker Image"]
CMD ["echo", "Cloning Enzyme SC 22 Files"]
WORKDIR /root
RUN git clone --recursive https://github.com/EnzymeAD/enzyme-sc22
WORKDIR /root/enzyme-sc22
RUN git checkout 8665560

#Install Julia
WORKDIR /root
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz 
RUN tar zxvf julia-1.7.3-linux-x86_64.tar.gz
ENV PATH "$PATH:/root/julia-1.7.3/bin/"

#Build llvm-project
WORKDIR /root/enzyme-sc22/llvm-project
RUN mkdir build
WORKDIR /root/enzyme-sc22/llvm-project/build
RUN cmake ../llvm -GNinja -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="llvm;clang;openmp" -DLLVM_TARGETS_TO_BUILD=X86
RUN ninja

#Build Enzyme
WORKDIR /root/enzyme-sc22/Enzyme/enzyme
RUN mkdir build
WORKDIR /root/enzyme-sc22/Enzyme/enzyme/build
RUN cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR=../../../llvm-project/build
RUN ninja

#Export ENV VALS
ENV ENZYME_PATH /root/enzyme-sc22/Enzyme/enzyme/build/Enzyme/ClangEnzyme-15.so
ENV CLANG_PATH /root/enzyme-sc22/llvm-project/build/bin

#BUILD LULESH-CPP
RUN cd /root/enzyme-sc22/LULESH-CPP
WORKDIR /root/enzyme-sc22/LULESH-CPP
RUN sed -i "s/\ttime/\t\/usr\/bin\/time/g" Makefile
RUN CLANG_PATH=$CLANG_PATH ENZYME_PATH=$ENZYME_PATH make -j

#BUILD LULESH-RAJA
WORKDIR /root/enzyme-sc22/LULESH-RAJA
RUN mkdir build
WORKDIR /root/enzyme-sc22/LULESH-RAJA/build
RUN cmake .. -G Ninja -DENABLE_OPENMP=ON -DLLVM_BUILD=$CLANG_PATH/.. -DENZYME=$ENZYME_PATH -DMPI_INCLUDE=/usr/lib/x86_64-linux-gnu/openmpi/include
RUN ninja

#BUILD LULESH.jl
WORKDIR /root/enzyme-sc22/LULESH.jl
RUN head -n -1 Project.toml > temp.txt ; mv temp.txt Project.toml
RUN /root/julia-1.7.3/bin/julia --project -e "import Pkg;Pkg.instantiate()"
RUN /root/julia-1.7.3/bin/julia --project -e 'import MPI; MPI.install_mpiexecjl(;destdir=".",force=true)'

#BUILD BUDE-OPENMP
WORKDIR /root/enzyme-sc22/BUDE/openmp
RUN make -j

#BUILD miniBUDE.jl
WORKDIR /root/enzyme-sc22/BUDE/miniBUDE.jl
RUN /root/julia-1.7.3/bin/julia --project=Threaded -e "import Pkg;Pkg.instantiate()"

#BUILD LULESH CoDiPack
WORKDIR /root
RUN git clone https://github.com/wsmoses/CODI-LULESH
WORKDIR /root/CODI-LULESH/lulesh-forward
RUN CLANG_PATH=$CLANG_PATH ENZYME_PATH=$ENZYME_PATH make
WORKDIR /root/CODI-LULESH/lulesh-gradient
RUN CLANG_PATH=$CLANG_PATH ENZYME_PATH=$ENZYME_PATH make

#List all executables
WORKDIR /root
RUN ls /root/enzyme-sc22/LULESH-CPP/
RUN ls /root/enzyme-sc22/LULESH-RAJA/build/bin/
RUN ls /root/enzyme-sc22/LULESH.jl/
RUN ls /root/enzyme-sc22/BUDE/openmp/
RUN ls /root/enzyme-sc22/BUDE/miniBUDE.jl/
RUN ls /root/CODI-LULESH/lulesh-forward/
RUN ls /root/CODI-LULESH/lulesh-gradient/

#Setup a non root user
RUN chown -hR myuser /root
USER myuser
