# Build instructions

These build instructions were built and Tested on Ubuntu 24.04.4. Because the original build tools were made for Ubuntu 22.04, Docker will be used to set up a controlled and predictable environment.

Many issues were encountered in the development of these instructions. You can find the documentation for those issues [here](./Problems_and_Solutions.md).

### You will need:

- Docker
- Vivado/Vitis 2024.1
- PetaLinux Tools 2024.1

## Pulling the Repo
At the location you wish to clone the repo, execute the following commands:

```bash
git clone https://github.com/Xilinx/AUP-ZU3.git
cd AUP-ZU3 && git submodule init && git submodule update
```
## Modifying the Dockerfile

Once the submodule has been pulled, the Docker image needs to be set up

```bash
cd pynq/sdbuild
```

From this directory, the existing Dockerfile needs to be modified

Add `diffstat`, `lz4`, and `zstd` to the host packages section, as shown here:

```Dockerfile
&& apt-get install -y \
bc libtool-bin gperf bison flex texi2html texinfo help2man gawk libtool \
build-essential automake libglib2.0-dev libfdt-dev device-tree-compiler \
qemu-user-static binfmt-support multistrap git lib32z1 lib32stdc++6 \
libssl-dev kpartx dosfstools nfs-common zerofree u-boot-tools rpm2cpio \
libsdl1.2-dev libpixman-1-dev libc6-dev chrpath socat zlib1g-dev unzip \
rsync python3-pip gcc-multilib xterm net-tools ninja-build python3-testresources \
libncurses5-dev libncursesw5-dev vim nano tmux zip dnsutils sudo binfmt-support \
    dbus-x11 libswt-glx-gtk-4-jni libgtk2.0-0 xvfb  diffstat \
```

Add `pyyaml` to the following line as shown:

```Dockerfile
RUN pip3 install --no-cache-dir --upgrade "setuptools>=24.2.0" numpy cffi pyyaml
```

Near the end of the Dockerfile, replace `WORKDIR /workspace` with `WORKDIR /AUP-ZU3`. IT IS ESSENTIAL THAT THE DIRECTORY BE NAMED AUP-ZU3.


You can now build the Docker Image:

```bash
docker build \
--build-arg USERNAME=$(whoami) \
--build-arg USER_UID=$(id -u) \
--build-arg USER_GID=$(id -g) \
-t pynqdock:latest .
```

## Docker Automation

Now that the Docker Image is set up, it can be somewhat automated.

Return to the root directory of the repo:

```bash
cd ../..
```

Create a new file called `start_docker.sh`, and insert the following contents:

```bash
#!/usr/bin/env bash

docker run \
--init \
--rm \
-it \
-v /tools/Xilinx:/tools/Xilinx:ro \
-v /home/user/Documents/SDKs/PetaLinux:/home/user/Documents/SDKs/PetaLinux:ro \
-v $(pwd):/AUP-ZU3 \
--name pynq-sdbuild-env \
--privileged \
pynqdock:latest \
/bin/bash
```

Note: Replace `/tools/Xilinx` and `/home/user/Documents/SDKs/PetaLinux` with the actual locations of your Vivado/Vitis and PetaLinux installs. It is important that the Path to PetaLinux matches for both the host path and the container path, as PetaLinux Tools will reference the actual path. *(Ensure you have versions 2024.1 installed!)*

Make the file executable

```bash
chmod +x start_docker.sh
```

In order to ensure Xilinx tools are easily available for the build toolchain, another script can be made. Title this one `sourceEnv.sh`:

```bash
#!/usr/bin/env bash

source /tools/Xilinx/Vivado/2024.1/settings64.sh
source /tools/Xilinx/Vitis/2024.1/settings64.sh
source /home/user/petalinux/settings.sh
```

These should include the actual paths to these resources as seen in the container.

Make the script executable

```bash
chmod +x sourceEnv.sh
```

## Setting up the Filesystem and Distribution Binaries

Next, the Prebuilt board-agnostic root filesystem, and prebuilt source distribution binaries are needed. They can be found [here](https://www.pynq.io/boards.html). Be sure to choose aarch64 for the rootfs.

In the repository, copy the archives to `pynq/sdbuild/prebuilt/` as:
- `pynq/sdbuild/prebuilt/pynq_rootfs.aarch64.tar.gz` for the rootfs.
- `pynq/sdbuild/prebuilt/pynq_sdist.tar.gz` for the source distribution binaries.

## Modifications to Host

Some parts of the build process will fail if Unprivleged Namespaces are not allowed on the system. This can be addressed for the duration of the build with:

```bash
sudo sysctl -w kernel.unprivileged_userns_clone=1
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

Additionally QEMU emulation for the build will require these to be installed on your host system:

```bash
sudo apt-get install -y qemu-user-static binfmt-support
```

## Verification

Once the Filesystem and Distribution Binaries are in place, enter the Docker Container. At the root directory of the repo:

```bash
./start_docker.sh
```

Once the Docker container has loaded, source your `sourceEnv.sh` script to ensure your Xilinx tools are available on the path for the build toolchain:

```bash
source sourceEnv.sh
```

Note: as long as your container is Running Ubuntu 22.04, and you installed PetaLinux Tools 2024.1, you can safely ignore the `[WARNING] This is not a supported OS` message.

To verify the setup, use the PYNQ makefile:

```bash
cd pynq/sdbuild
make checkenv BOARDS=AUP-ZU3
```

## Building - Subject to Change (Doesn't work yet!)

To build the entire PYNQ SD Image, run the following from the root directory of the repo:

For the 4GB Variant:

```bash
make image-4gb 2>&1 | tee build.log
```

For the 8GB Variant:
```bash
make image-8gb 2>&1 | tee build.log
```

Or, to only build the base design:

```bash
cd base
make
```
