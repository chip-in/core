FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget sudo lsof telnet bind-utils tar tcpdump vim sysstat strace less
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
RUN yum install -y epel-release httpd
RUN yum install -y mosquitto certbot
ENV NODEJS_VERSION=v8.5.0
RUN wget -qO - https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz | tar xf - -C /usr/local -J \
  && ln -s /usr/local/node-${NODEJS_VERSION}-linux-x64 /usr/local/nodejs
RUN wget -qO - https://github.com/procube-open/shibboleth-fcgi-rpm/releases/download/3.0.1-3.2/shibboleth-fcgi-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/nginx-shib-rpm/releases/download/1.15.3-3/nginx-shib-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/configure/releases/download/1.3/configure-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/jwt-nginx-lua/releases/download/1.0.3/jwt-nginx-lua.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/hmr/releases/download/0.2/hmr-rpm.tar.gz | tar -xzf -
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
RUN touch /etc/sysconfig/network
RUN systemctl disable getty.target
ENV container docker
STOPSIGNAL 37
EXPOSE 80
EXPOSE 443
CMD ["/sbin/init"]
