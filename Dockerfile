FROM ubuntu
MAINTAINER Lorenzo Salvadorini <lorello@openweb.it>

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y puppet curl
RUN curl https://raw.github.com/lorello/ubuntu-boxen/master/install.sh | sh
RUN uboxen
