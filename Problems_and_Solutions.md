# AUP-ZU3 Build Problems and Solutions

Building from complex build toolchains is very messy and error-prone, which can lead to a frustrating, iterative process. This document is intended to clearly indicate the issues that occurred when attempting to build an SD image for the AUP-ZU3 board.


## Sourcing PetaLinux tools warns "/bin/sh is not bash!"
### Problem
When sourcing PetaLinux tools inside the Docker Container with `source /home/user/petalinux/settings.sh` the following message is displayed:

    WARNING: /bin/sh is not bash!

This is due to the container using /bin/sh as a symlink for dash, instead of bash.

### Solution

To address this, the Dockerfile located at `AUP-ZU3/pynq/sdbuild/Dockerfile` can be modified to ensure the /bin/sh symlink points to bash.

The Dockerfile contains the following section:

```Dockerfile
# Enable i386 architecture and install core dependencies
RUN dpkg --add-architecture i386 \
 # Install build and host packages
 && apt-get install -y \
    bc libtool-bin gperf bison flex texi2html texinfo help2man gawk libtool \
    build-essential automake libglib2.0-dev libfdt-dev device-tree-compiler \
    qemu-user-static binfmt-support multistrap git lib32z1 lib32stdc++6 \
    libssl-dev kpartx dosfstools nfs-common zerofree u-boot-tools rpm2cpio \
    libsdl1.2-dev libpixman-1-dev libc6-dev chrpath socat zlib1g-dev unzip \
    rsync python3-pip gcc-multilib xterm net-tools ninja-build python3-testresources \
    libncurses5-dev libncursesw5-dev vim nano tmux zip dnsutils sudo binfmt-support \
    dbus-x11 libswt-glx-gtk-4-jni libgtk2.0-0 xvfb \
 # Configures timezone interactively (2: Americas, 37: Central)
 && echo -e '2\n37\n' | apt-get install -y lsb-core \
 # Locale for Vivado
 && locale-gen en_US.utf8 && update-locale \
 # Clean up APT
 && rm -rf /var/lib/apt/lists/*

```

Just before the ```# Clean up APT``` comment, the following can be added:

```Dockerfile
 # Change system default /bin/sh from dash to bash
 && echo "dash dash/sh boolean false" | debconf-set-selections \
 && dpkg-reconfigure --frontend noninteractive dash \
```

Once the changes have been made, the Docker Image can be rebuilt.


## `make checkenv` fails

### Problem

The [AUP-ZU3 Build Instructions](https://github.com/Xilinx/AUP-ZU3/tree/main) indicate that the environment can be verified with:

```bash
cd pynq/sdbuild
make checkenv
```
However, this can fail for several reasons.

1) The command is incomplete
2) The rootfs is missing
3) Vivado and petalinux aren't sourced properly

### Solution

1) The command is incomplete, and does not properly address the needs of the AUP-ZU3 build toolchain. The proper command is as follows:

```bash
make checkenv REBUILD_PYNQ_ROOTFS=True BOARDS=AUP-ZU3
```
This command ensures the build environment is being checked for the appropriate board.

2) If the rootfs file isn't properly included, `make checkenv` will fail. The build system expects the rootfs to be located under `AUP-ZU3/pynq/sdbuild/prebuilt/pynq_rootfs.aarch64.tar.gz`. The file can be downloaded from [here](https://www.pynq.io/boards.html#). Ensure when the file is added, it is renamed to exactly `pynq_rootfs.aarch64.tar.gz`.

3) If Vivado and petalinux are not properly sourced, `make checkenv` will fail. Verify that they are properly addressed according to their actual file paths within the Docker container:

```bash
source /tools/Xilinx/Vivado/2024.1/settings64.sh
source /home/user/petalinux/settings.sh
```
Note: Ensure to source with your actual paths for Vivado, and petalinux tools, they may vary from the paths shown in the example above.

## "No rule to make target `'/workspace/pynq/sdbuild/boot/image_.its'`"

### Problem
The build fails with the message:

    make[1]: *** No rule to make target '/workspace/pynq/sdbuild/boot/image_.its', needed by '/workspace/pynq/sdbuild/build/workspace/image.its'.  Stop.
    make[1]: Leaving directory '/workspace/pynq/sdbuild'
    make: *** [Makefile:22: image] Error 2

This is due to a directory naming mismatch that the toolchain is relying on. The directory of the repo is named AUP-ZU3, however the Pynq build instructions name the directory /workspace for the container.

### Solution

Modify the Dockerfile and docker command to name the directory /AUP-ZU3 instead of /workspace:

In the Dockerfile, there is a line near the end that says `WORKDIR /workspace`. Replace the line with `WORKDIR /AUP-ZU3`, and rebuild the docker image.

In the docker command, replace the mount `-v $(pwd):/workspace` with `-v $(pwd):/AUP-ZU3`.

## Missing Utilities

### Problem

Some of the required utilities for the toolchain are missing from the Dockerfile in the AUP-ZU3/pynq/sdbuild

Notably:

- diffstat
- lz4
- zstd

### Solution

The Dockerfile includes the following section:

```bash
 # Install build and host packages
 && apt-get install -y \
    bc libtool-bin gperf bison flex texi2html texinfo help2man gawk libtool \
    build-essential automake libglib2.0-dev libfdt-dev device-tree-compiler \
    qemu-user-static binfmt-support multistrap git lib32z1 lib32stdc++6 \
    libssl-dev kpartx dosfstools nfs-common zerofree u-boot-tools rpm2cpio \
    libsdl1.2-dev libpixman-1-dev libc6-dev chrpath socat zlib1g-dev unzip \
    rsync python3-pip gcc-multilib xterm net-tools ninja-build python3-testresources \
    libncurses5-dev libncursesw5-dev vim nano tmux zip dnsutils sudo binfmt-support \
    dbus-x11 libswt-glx-gtk-4-jni libgtk2.0-0 xvfb \
```

This section can be easily modified to accomodate these missing dependencies by simply adding them to the list after xvfb, and separated by spaces. Once done, Docker image can be rebuilt.


## "Component `/AUP-ZU3/pynq/sdbuild/build/AUP-ZU3/petalinux_bsp/xilinx-aupzu3-2024.1` already exists."

### Problem

The build expects to create the `/AUP-ZU3/pynq/sdbuild/build/AUP-ZU3/petalinux_bsp/xilinx-aupzu3-2024.1` directory, however, it may already exist due to progress from previous build attempts.

### Solution

The `/AUP-ZU3/pynq/sdbuild/build/AUP-ZU3/petalinux_bsp/xilinx-aupzu3-2024.1` directory can be safely removed, and the build re-run. It will be regenerated on the next build. However, if the step that creates it is not fully completed before the next build, it may need to be manually removed once again.

## "ModuleNotFoundError"

### Problem

Some of the python modules needed are not explicitly included in the Docker image. Notably, `yaml` is missing.

### Solution

The Dockerfile contains the following line:
```Dockerfile
RUN pip3 install --no-cache-dir --upgrade "setuptools>=24.2.0" numpy cffi
```
The line can be modified to add `pyyaml` to the end, and the Docker image can be rebuilt.

## Permission Error: Operation Not Permitted

### Problem
Some operations in the container rely on permissions granted by the host kernel, regardless of if the container is started with the `--privileged` flag. In the case of an Ubuntu 24.04 host, AppArmor can cause the kernel to restrict the container namespaces.

### Solution

The AppArmor restriction can be disabled for the duration of the build with the following:

```bash
sudo sysctl -w kernel.unprivileged_userns_clone=1
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```


## "Unable to access 'https//github.com/...'

### Problem

Surprisingly, the problem was not actually with GitHub at all, rather, The [instructions](https://pynq.readthedocs.io/en/latest/pynq_sd_card.html) for setting up the build environment do not account for PetaLinux tools having a different installation path from the path within the container, as some of the installed config files point to the exact installed path.

### Solution

When mounting the location for PetaLinux tools inside the container, ensure that the path for the container matches the host path.



## "Command bitbake zocl failed"

### Problem
Because the paths used are cached earlier in the build, changing the petalinux paths later in the build can result in issues.
### Solution
These can be addressed by restoring the previous path to petalinux tools (which must have parity between the host and the container)