FROM ubuntu
MAINTAINER Lorenzo Salvadorini <lorello@openweb.it>

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y puppet curl
RUN apt-get install -y git sudo
RUN cd /opt && git clone https://github.com/lorello/ubuntu-boxen.git
RUN ln -s /opt/ubuntu-boxen/uboxen /usr/local/bin/uboxen
RUN /opt/ubuntu-boxen/uboxen 
