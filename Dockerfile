FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget sudo lsof telnet bind-utils tar tcpdump vim sysstat strace less
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
RUN yum install -y epel-release httpd
# RUN yum install -y mosquitto certbot
# mosquitto 1.6.10-1.el7 degrade for websocket
# https://github.com/eclipse/mosquitto/issues/1740
# so download from fedora archive
RUN yum install -y https://archive.fedoraproject.org/pub/archive/epel/7.2020-04-20/x86_64/Packages/m/mosquitto-1.6.8-1.el7.x86_64.rpm certbot
ENV NODEJS_VERSION=v16.14.0
RUN wget -qO - https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz | tar xf - -C /usr/local -J \
  && ln -s /usr/local/node-${NODEJS_VERSION}-linux-x64 /usr/local/nodejs && ln -s /usr/local/nodejs/bin/node /usr/bin/node && ln -s /usr/local/nodejs/bin/npm /usr/bin/npm
RUN wget -qO - https://github.com/procube-open/shibboleth-fcgi-rpm/releases/download/3.0.1-3.2/shibboleth-fcgi-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/nginx-shib-rpm/releases/download/1.15.3-3/nginx-shib-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/configure/releases/download/1.7.9/configure-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/jwt-nginx-lua/releases/download/1.0.8/jwt-nginx-lua.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/hmr/releases/download/0.5.13/hmr-rpm.tar.gz | tar -xzf -
RUN yum install -y RPMS/{noarch,x86_64}/*.rpm \
  && mkdir /etc/systemd/system/nginx.service.d \
  && printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
RUN systemctl enable nginx mosquitto shibd shibfcgi hmr \
  jwtIssuer-config jwtVerifier-config logserver-config renewCerts.timer shibboleth-config load-certificates nginx-config
RUN echo -e "port 1833\nprotocol websockets" >> /etc/mosquitto/mosquitto.conf
RUN mkdir -p /usr/local/chip-in/mosquitto/ \
  && mkdir -p /var/log/mosquitto \
  && wget -qO - https://github.com/chip-in/mqtt-auth-plugin/releases/download/0.1.4/chipin_auth_plug.so > /usr/local/chip-in/mosquitto/chipin_auth_plug.so \
  && echo -e '/var/log/mosquitto/*log {\ndaily\nmissingok\nrotate 52\ncompress\ndelaycompress\ncopytruncate\n}' > /etc/logrotate.d/mosquitto
RUN echo 'tr "\000" "\n" < /proc/1/environ > /etc/sysconfig/hmr' >> /usr/local/chip-in/hmr/env.sh
RUN touch /etc/sysconfig/network
RUN systemctl disable getty.target
ENV container docker
STOPSIGNAL 37
EXPOSE 80
EXPOSE 443
CMD ["/sbin/init"]
