FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget sudo lsof telnet bind-utils tar tcpdump vim sysstat strace
ENV HOME /root
WORKDIR ${HOME}
RUN yum install -y epel-release httpd
RUN yum install -y mosquitto certbot
RUN wget -qO - https://github.com/chip-in/shibboleth-fcgi-rpm/releases/download/2.6.0-2.2-1/shibboleth-fcgi-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/nginx-shib-rpm/releases/download/1.12.1-1-1/nginx-shib-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/configure/releases/download/1.0.0-1.1/configure-rpm.tar.gz | tar -xzf -
RUN yum install -y RPMS/x86_64/*.rpm \
  && mkdir /etc/systemd/system/nginx.service.d \
  && printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
RUN systemctl enable nginx mosquitto shibd shibfcgi
CMD ["/sbin/init"]
