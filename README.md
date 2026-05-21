# Build instructions

## Pulling the Repo
At the location you wish to clone the repo, execute the following commands:

```bash
    git clone https://github.com/Xilinx/AUP-ZU3.git
    cd AUP-ZU3 && git submodule init && git submodule update
```
## Modifying the Dockerfile

Once the submodule has been pulled, we need to set up the Docker image

```bash
    cd pynq/sdbuild
```

From this directory, we need to modify the existing Dockerfile

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

Now that we have our Docker Image set up, we can automate things somewhat.

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
    -v /home/user/Documents/SDKs/PetaLinux:/home/user/petalinux:ro \
    -v $(pwd):/AUP-ZU3 \
    --name pynq-sdbuild-env \
    --privileged \
    pynqdock:latest \
    /bin/bash
```

Note: Replace `/tools/Xilinx` and `/home/user/Documents/SDKs/PetaLinux` with the actual locations of your Vivado/Vitis and PetaLinux installs. *(Ensure you have versions 2024.1 installed!)*

Make the file executable

```bash
    chmod +x start_docker.sh
```

In order to ensure your Xilinx tools are easily available for the build toolchain, we can create another script. We will call this one `sourceEnv.sh`:

```bash
    #!/usr/bin/env bash

    source /tools/Xilinx/Vivado/2024.1/settings64.sh
    source /home/user/petalinux/settings.sh
```

The path does not have to match your actual path, because these just need to match the paths in the container.

Make the script executable

```bash
    chmod +x sourceEnv.sh
```

## Setting up the Filesystem and Distribution Binaries

Next, we need to get the Prebuilt board-agnostic root filesystem, and prebuilt source distribution binaries. They can be found [here](https://www.pynq.io/boards.html). Be sure to choose aarch64 for the rootfs.

In the repository, copy the archives to `pynq/sdbuild/prebuilt/` as:
- `pynq/sdbuild/prebuilt/pynq_rootfs.aarch64.tar.gz` for the rootfs.
- `pynq/sdbuild/prebuilt/pynq_sdist.tar.gz` for the source distribution binaries.

## Verification

Once we have the Filesystem and Distribution Binaries in place, we can enter our Docker Container. At the root directory of the repo:

```bash
    ./start_docker.sh
```

Once the Docker container has loaded, source your `sourceEnv.sh` script to ensure your Xilinx tools are available on the path for the build toolchain:

```bash
    source sourceEnv.sh
```

To verify the setup, we can use the PYNQ makefile:

```bash
    cd pynq/sdbuild
    make checkenv BOARDS=AUP-ZU3
```

## Building

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
