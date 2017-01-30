## Open BMC Verified Boot Tests

This is a set of integration tests for Open BMC's verified-boot built using U-Boot's verified-boot features.

The included `Dockerfile` builds:
- U-Boot from Open BMC
- QEMU with a basic model for the ASPEED AST2500 EDK
- Several forms of Open BMC flash content

The forms built are designed as input to test cases.
The final execution in the `Dockerfile` runs the `tests.py` test harness.

### How to test

Install docker on Ubuntu (or your favorite OS):
- `apt-get install docker.io`

Run the build:
- `docker build .; echo $?`

A return code == 0 is success, otherwise check stdout/stderr for the inconsistent expectation.

### Private keys

Note there **are several private keys** included here. These are lame and only included for consistent test cases.

### TODO

- Include another `Dockerfile` that stands up recovery infrastructure.
- Write the R/W flash environment to enforce verified-boot in software-mode.
- Include another EDK model to enforce verified-boot in hardware-mode.
- Allow the model to reboot and inspect SRAM for retries.
