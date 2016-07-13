FROM starlabio/ubuntu-base:1.0
MAINTAINER Doug Goldstein <doug@starlab.io>

# setup linkers for Cargo
RUN mkdir -p /root/.cargo/
RUN echo "[target.aarch64-unknown-linux-gnu]\r\nlinker = \"aarch64-linux-gnu-gcc\"" >> /root/.cargo/config
RUN echo "[target.arm-unknown-linux-gnueabihf]\r\nlinker = \"arm-linux-gnueabihf-gcc\"" >> /root/.cargo/config

# install rustup
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && sh ./rustup-install.sh  -y && rm rustup-install.sh

# Install x86_64 Rust
RUN /root/.cargo/bin/rustup default 1.10.0-x86_64-unknown-linux-gnu
# Install AARCH64 Rust
RUN /root/.cargo/bin/rustup toolchain install 1.10.0-aarch64-unknown-linux-gnu
# Install 32-bit ARM Rust
RUN /root/.cargo/bin/rustup toolchain install 1.10.0-arm-unknown-linux-gnueabihf

# Install rustfmt / cargo fmt for testing
RUN cargo install --root /usr/local rustfmt --vers 0.5.0

# setup fetching arm packages
RUN dpkg --add-architecture arm64 && dpkg --add-architecture armhf

# Ubuntu can't be an adult with their sources list for arm
RUN sed -e 's:deb h:deb [arch=amd64] h:' -e 's:deb-src h:deb-src [arch=amd64] h:' -i /etc/apt/sources.list && \
        find /etc/apt/sources.list.d/ -type f -exec sed -e 's:deb h:deb [arch=amd64] h:' -e 's:deb-src h:deb-src [arch=amd64] h:' -i {} \; && \
        sed -e 's:arch=amd64:arch=armhf,arm64:' -e 's:security:ports:' -e 's://.*archive://ports:' -e 's:/ubuntu::' /etc/apt/sources.list | grep 'ubuntu.com' | grep -v '\-ports' | tee /etc/apt/sources.list.d/arm.list

# package depends
RUN apt-get update && \
    apt-get --quiet --yes install \
        libnl-3-dev texinfo libnl-utils software-properties-common \
        libnl-cli-3-dev libbz2-dev libpci-dev m4 cmake gcc-multilib \
        gettext bin86 bcc acpica-tools uuid-dev ncurses-dev \
        libaio-dev libyajl-dev libkeyutils-dev \
        linux-headers-4.2.0-22-generic clang-3.7 cppcheck libtspi-dev lcov \
        gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu libssl-dev:armhf \
        libssl-dev:arm64 libkeyutils1:arm64 libkeyutils-dev:arm64 \
        libkeyutils1:armhf libkeyutils-dev:armhf && \
        apt-get autoremove -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists* /tmp/* /var/tmp/*

# Install behave and hamcrest for testing
RUN pip install behave pyhamcrest