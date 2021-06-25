FROM ubuntu:latest

MAINTAINER Benno Bielmieier "benno.bielmeier@st.othr.de"

# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t petalinux:2020.2 ."

# install dependences:

## Do not pull from China
# ARG UBUNTU_MIRROR=mirror.tuna.tsinghua.edu.cn
# RUN sed -i.bak s/archive.ubuntu.com/${UBUNTU_MIRROR}/g /etc/apt/sources.list && \
#   dpkg --add-architecture i386 && apt-get update &&  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y -q \
  sudo \
  expect \
  tzdata \
  locales \
  rsync \
  libncurses5 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD https://www.xilinx.com/Attachment/plnx-env-setup.sh /
RUN chmod +x /plnx-env-setup.sh
RUN /plnx-env-setup.sh

RUN dpkg --add-architecture i386 &&  apt-get update &&  \
      apt-get install -y -q \
      zlib1g:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


ARG PETA_VERSION
ARG PETA_RUN_FILE

RUN locale-gen en_US.UTF-8 && update-locale

# Make a Vivado user
RUN adduser --disabled-password --gecos '' vivado && \
  usermod -aG sudo vivado && \
  echo "vivado ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY accept-eula.sh ${PETA_RUN_FILE} /

# Run the install
RUN chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u vivado -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

# Make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

USER vivado
ENV HOME /home/vivado
ENV LANG en_US.UTF-8
RUN mkdir /home/vivado/project
WORKDIR /home/vivado/project

# Add vivado tools to path
RUN echo "source /opt/Xilinx/petalinux/settings.sh" >> /home/vivado/.bashrc

# Disable telemetry
RUN petalinux-util --webtalk off

ARG PETA_BSP

COPY ${PETA_BSP} /home/vivado
