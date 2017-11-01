FROM debian:sid

# Basic docker image to get LAVA dispatcher running with QEMU device type
# Launch: docker run -it --privileged -u lava docker-lava-dispatcher bash

RUN  echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections \
 && apt update \
 && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
 bridge-utils \
 busybox \
 git \
 lava-dispatcher \
 libguestfs-tools \
 linux-image-amd64 \
 locales \
 openssh-server \
 qemu-kvm \
 qemu-system-arm \
 qemu-system-x86 \
 qemu-user-static \
 ser2net \
 vim \
 && apt clean \
 && rm -rf \
 /etc/apt/sources.list.d/*.key \
 /var/lib/apt/lists/* \
 /tmp/* \
 /var/tmp/*

# Example to generate the keyring.cfg
# lava-tool auth-add https://foo.bar@validation.linaro.org/RPC2
# lava-tool auth-config --default-user https://foo.bar@validation.linaro.org/RPC2
# lava-tool auth-config --endpoint-shortcut production https://foo.bar@validation.linaro.org/RPC2
# lava-tool auth-list

COPY keyring.cfg .
RUN useradd -m -G plugdev lava \
 && echo 'lava ALL = NOPASSWD: ALL' > /etc/sudoers.d/lava \
 && chmod 0440 /etc/sudoers.d/lava \
 && mkdir -p /var/run/sshd /home/lava/bin /home/lava/.ssh /home/lava/.local/share/lava-tool /home/lava/output \
 && mv keyring.cfg /home/lava/.local/share/lava-tool/ \
 && chmod 0600 /home/lava/.local/share/lava-tool/keyring.cfg \
 && chmod 0700 /home/lava/.ssh \
 && chown -R lava:lava /home/lava/bin /home/lava/.ssh /home/lava/.local /home/lava/output

USER lava
RUN lava-tool get-pipeline-device-config --output /home/lava/qemu-dispatcher01_config.yaml production qemu-dispatcher01 \
 && curl -s https://validation.linaro.org/static/docs/v2/examples/test-jobs/qemu-pipeline-first-job.yaml > /home/lava/qemu-pipeline-first-job.yaml \
 && sed -i 's/command:/command: qemu-system-x86_64/g' /home/lava/qemu-dispatcher01_config.yaml
# Bug reported in qemu-dispatcher01_config.yaml - command is empty
# sudo lava-run --job-id 01 --output-dir /home/lava/output --device qemu-dispatcher01_config.yaml qemu-pipeline-first-job.yaml

EXPOSE 22
