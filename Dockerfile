FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget sudo lsof telnet bind-utils tar tcpdump vim sysstat strace
ENV HOME /root
WORKDIR ${HOME}
ADD https://yum-repo.chip-in.net/chip-in/chip-in.repo /etc/yum.repos.d/
RUN yum install -y nginx \
  && mkdir /etc/systemd/system/nginx.service.d \
  && printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
RUN yum install -y epel-release httpd
RUN yum install -y mosquitto shibboleth
COPY core.conf /etc/nginx/conf.d/core.conf
RUN systemctl enable nginx mosquitto shibd shibfcgi
CMD ["/sbin/init"]
