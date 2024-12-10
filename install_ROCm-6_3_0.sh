#!/bin/bash
#SBATCH -N 1
#SBATCH -n 32
#SBATCH -p rc
#SBATCH -t 8:00:00

# Setting up the environment
source env_ROCm-6_3_0.sh

# Creating the src directory for the installed application
mkdir -p $SOFTWARE_DIRECTORY/src

# Installing $SOFTWARE_NAME/$SOFTWARE_VERSION
# Installing ROCm 6.3.0
cd $SOFTWARE_DIRECTORY/src
wget https://github.com/ROCm/llvm-project/archive/refs/tags/rocm-6.3.0.tar.gz
tar -xvf rocm-6.3.0.tar.gz
cd llvm-project-rocm-6.3.0/amd/hipcc
mkdir -p build
cd build
cmake ..
make

cd $SOFTWARE_DIRECTORY/src
export ROCM_BRANCH=rocm-6.3.0
git clone -b "$ROCM_BRANCH" https://github.com/ROCm/clr.git
git clone -b "$ROCM_BRANCH" https://github.com/ROCm/hip.git
git clone -b "$ROCM_BRANCH" https://github.com/ROCm/hipother.git
export CLR_DIR="$(readlink -f clr)"
export HIP_DIR="$(readlink -f hip)"
export HIP_OTHER="$(readlink -f hipother)"
cd "$CLR_DIR"
mkdir -p build; cd build
cmake -DHIP_COMMON_DIR=$HIP_DIR -DHIP_PLATFORM=nvidia -DCMAKE_INSTALL_PREFIX=$PWD/install -DHIP_CATCH_TEST=0 -DCLR_BUILD_HIP=ON -DCLR_BUILD_OCL=OFF -DHIPNV_DIR=$HIP_OTHER/hipnv -DHIPCC_BIN_DIR=$SOFTWARE_DIRECTORY/src/llvm-project-rocm-6.3.0/amd/hipcc/build ..
make -j$(nproc)
make install

# Creating modulefile
touch $SOFTWARE_VERSION
echo "#%Module" >> $SOFTWARE_VERSION
echo "module-whatis	 \"Loads $SOFTWARE_NAME/$SOFTWARE_VERSION module." >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "This module was built on $(date)" >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "ROCm (https://github.com/ROCm/HIP) HIP: C++ Heterogeneous-Compute Interface for Portability." >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "The script used to build this module can be found here: $GITHUB_URL" >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "To load the module, type:" >> $SOFTWARE_VERSION
echo "module load cuda/12.3.0" >> $SOFTWARE_VERSION
echo "module load $SOFTWARE_NAME/$SOFTWARE_VERSION" >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "\"" >> $SOFTWARE_VERSION
echo "" >> $SOFTWARE_VERSION
echo "conflict	 $SOFTWARE_NAME" >> $SOFTWARE_VERSION
echo "prepend-path	 PATH $SOFTWARE_DIRECTORY/src/clr/build/install/bin" >> $SOFTWARE_VERSION
echo "prepend-path       LD_LIBRARY_PATH $SOFTWARE_DIRECTORY/src/clr/build/install/lib64" >> $SOFTWARE_VERSION
echo "prepend-path       LIBRARY_PATH $SOFTWARE_DIRECTORY/src/clr/build/install/lib64" >> $SOFTWARE_VERSION
echo "prepend-path       CPATH $SOFTWARE_DIRECTORY/src/clr/build/install/include" >> $SOFTWARE_VERSION

# Moving modulefile
mkdir -p $CLUSTER_DIRECTORY/modulefiles/$SOFTWARE_NAME
cp $SOFTWARE_VERSION $CLUSTER_DIRECTORY/modulefiles/$SOFTWARE_NAME/$SOFTWARE_VERSION
cp $SOFTWARE_VERSION $CURRENT_PATH
