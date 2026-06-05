#!/usr/bin/env bash

# Clone Main Repo
git clone https://github.com/Xilinx/AUP-ZU3.git
cd AUP-ZU3

# Apply patch to add Docker initialization and source scripts
git apply ../ver_1.patch

# Clone pynq submodule
git submodule init && git submodule update
cd pynq

# Apply patch to add dependencies to Docker Image and QEMU configurations
git apply ../../submodule.patch
cd sdbuild

# Build the Docker Image
docker build \
--build-arg USERNAME=$(whoami) \
--build-arg USER_UID=$(id -u) \
--build-arg USER_GID=$(id -g) \
-t pynqdock:latest .


# Download prebuilt rootfs and source distribution
cd prebuilt
curl -L "https://download.amd.com/opendownload/pynq/jammy.aarch64.3.1.0.tar.gz" -o pynq_rootfs.aarch64.tar.gz
curl -L "https://download.amd.com/opendownload/pynq/pynq-3.1.2.tar.gz" -o pynq_sdist.tar.gz

cd ../../..


# Rewrite Petalinux Path, if Applicable
if [ "$#" -eq 1 ] || [ "$#" -eq 2 ]; then

        NEW_PL_PATH="$1"

        sed -i "s|/home/user/petalinux|${NEW_PL_PATH}|g" "start_docker.sh"
        sed -i "s|/home/user/petalinux|${NEW_PL_PATH}|g" "sourceEnv.sh"

fi

# Rewrite Xilinx Tools Path, if Applicable
if [ "$#" -eq 2 ]; then

        NEW_XL_PATH="$2"

        sed -i "s|/tools/Xilinx|${NEW_XL_PATH}|g" "start_docker.sh"
        sed -i "s|/tools/Xilinx|${NEW_XL_PATH}|g" "sourceEnv.sh"

fi
