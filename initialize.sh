#!/usr/bin/env bash

git clone https://github.com/Xilinx/AUP-ZU3.git
cd AUP-ZU3
git apply ../ver_1.patch
git submodule init && git submodule update
cd pynq
git apply ../../submodule.patch
cd sdbuild
docker build \
--build-arg USERNAME=$(whoami) \
--build-arg USER_UID=$(id -u) \
--build-arg USER_GID=$(id -g) \
-t pynqdock:latest .

cd prebuilt
curl -L "https://download.amd.com/opendownload/pynq/jammy.aarch64.3.1.0.tar.gz" -o pynq_rootfs.aarch64.tar.gz
curl -L "https://download.amd.com/opendownload/pynq/pynq-3.1.2.tar.gz" -o pynq_sdist.tar.gz

cd ../../..

if [ "$#" -eq 1 ] || [ "$#" -eq 2 ]; then

        NEW_PL_PATH="$1"

        sed -i "s|/home/user/petalinux|${NEW_PL_PATH}|g" "start_docker.sh"
        sed -i "s|/home/user/petalinux|${NEW_PL_PATH}|g" "sourceEnv.sh"

fi

if [ "$#" -eq 2 ]; then

        NEW_XL_PATH="$2"

        sed -i "s|/tools/Xilinx|${NEW_XL_PATH}|g" "start_docker.sh"
        sed -i "s|/tools/Xilinx|${NEW_XL_PATH}|g" "sourceEnv.sh"

fi
