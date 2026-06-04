# AUP-ZU3 Automated Build Instructions

These instructions are aimed at simplifying the initalization  process for building the Pynq Linux image for the AUP-ZU3 board.

## You will need:

- included files in the directory you wish to clone the repository to
    - initialize.sh
    - ver_1.patch
    - submodule.patch
- PetaLinux Tools 2024.1
- Vivado/Vitis 2024.1
- Docker
- git
- qemu-user-static and binfmt-support
- AppArmor Disabled

## Initialize Build System

Once the three files `initialize.sh`, `ver_1.patch`, and `submodule.patch` are in the directory you wish to clone the build repository to, you can simply run:

```bash
./initialize.sh
```

`initialize.sh` does several things for your convenience:

- Clones AUP-ZU3 repository and initializes submodules
- Patches repository with modified files for the build system
    - Modifies the Dockerfile located at `pynq/sdbuild/Dockerfile` to ensure Docker image meets container requirements for build
    - Modifies `pynq/sdbuild/packages/xrtlib/qemu.sh` to ensure successful builds
    - Creates `start_docker.sh` for user convenience
    - Creates `sourceEnv.sh` for user convenience
- Builds the Docker image based on the `pynq/sdbuild/Dockerfile`
- Downloads the prebuilt rootfs to `pynq/sdbuild/prebuilt/pynq_rootfs.aarch64.tar.gz`
- Downloads the prebuilt source distribution to `pynq/sdbuild/prebuilt/pynq_sdist.tar.gz`
- Replace path names to Xilinx Tools and PetaLinux Tools (If Necessary)

### Configuring paths

The Initialize script is designed to take up to 2 arguments. The first argument will replace the default path to PetaLinux Tools (`/home/user/petalinux`), the second argument will replace the default path to Xilinx Tools (`/tools/Xilinx`).

This can be done by entering your own paths to PetaLinux Tools, and Xilinx Tools, omitting the `/` on the last directory.

Example:

```bash
./initialize.sh /path/to/petalinux
```

OR

```bash
./initialize.sh /path/to/petalinux /path/to/Xilinx
```


## Things to be done manually

This automated system hasn't been completed yet, so some manual work is still required of the user.

### AppArmor must be disabled

QEMU requires AppArmor be disabled. This can be done simply with:

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

### QEMU Dependencies must be installed

QEMU requires the following dependencies to be installed:

```bash
sudo apt-get install -y qemu-user-static binfmt-support
```

### Sourcing and Verification must be done manually

The environment must be manually verified

Once the Filesystem and Distribution Binaries are in place, enter the Docker Container. At the root directory of the repo:

```bash
./start_docker.sh
```

Once the Docker container has loaded, source your `sourceEnv.sh` script to ensure your Xilinx tools are available on the path for the build toolchain:

```bash
source sourceEnv.sh
```

Note: as long as your container is Running Ubuntu 22.04, and you installed PetaLinux Tools 2024.1, you can safely ignore the `[WARNING] This is not a supported OS` message, if present.

To verify the setup, use the PYNQ makefile:

```bash
cd pynq/sdbuild
make checkenv REBUILD_PYNQ_ROOTFS=True BOARDS=AUP-ZU3
```


### Starting the build

To build the entire PYNQ SD Image, run the following from the root directory of the repo (still inside the container):

For the 4GB Variant:

```bash
make image-4gb 2>&1 | tee build.log
```

For the 8GB Variant:
```bash
make image-8gb 2>&1 | tee build.log
```

After a successful build, the image can be found in the AUP-ZU3/pynq/sdbuild/output/ directory.

Or, to only build the base design:

```bash
cd base
make
```