FROM centos:7
RUN yum -y update \
    && yum -y install unzip wget sudo lsof telnet bind-utils tar tcpdump vim sysstat strace less
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
RUN yum install -y epel-release httpd yum-utils
RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
RUN yum install -y mosquitto-1.6.10-1.el7.x86_64 certbot
ENV NODEJS_VERSION=v16.19.1
RUN wget -qO - https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz | tar xf - -C /usr/local -J \
  && ln -s /usr/local/node-${NODEJS_VERSION}-linux-x64 /usr/local/nodejs && ln -s /usr/local/nodejs/bin/node /usr/bin/node && ln -s /usr/local/nodejs/bin/npm /usr/bin/npm
RUN wget -qO - https://github.com/procube-open/shibboleth-fcgi-rpm/releases/download/3.0.1-3.2/shibboleth-fcgi-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/nginx-shib-rpm/releases/download/1.15.3-3/nginx-shib-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/configure/releases/download/v1.7.14-rc5ca2dd22.2/configure-rpm.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/procube-open/jwt-nginx-lua/releases/download/1.0.10/jwt-nginx-lua.tar.gz | tar -xzf -
RUN wget -qO - https://github.com/chip-in/hmr/releases/download/v0.6.8-rc7258e89d.1/hmr-rpm.tar.gz | tar -xzf -
RUN yum install -y RPMS/{noarch,x86_64}/*.rpm \
  && mkdir /etc/systemd/system/nginx.service.d \
  && printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
RUN systemctl enable nginx mosquitto shibd shibfcgi hmr \
 jwtIssuer-config jwtVerifier-config logserver-config renewCerts.timer shibboleth-config load-certificates nginx-config
RUN mkdir -p /usr/local/chip-in/mosquitto/ \
  && mkdir -p /var/log/mosquitto \
  && wget -qO - https://github.com/chip-in/mqtt-auth-plugin/releases/download/v0.1.10/chipin_auth_plug.so > /usr/local/chip-in/mosquitto/chipin_auth_plug.so \
  && echo -e '/var/log/mosquitto/*log {\ndaily\nmissingok\nrotate 52\ncompress\ndelaycompress\ncopytruncate\n}' > /etc/logrotate.d/mosquitto
RUN echo 'tr "\000" "\n" < /proc/1/environ > /etc/sysconfig/hmr' >> /usr/local/chip-in/hmr/env.sh
RUN touch /etc/sysconfig/network
RUN systemctl disable getty.target
ENV container docker
STOPSIGNAL 37
EXPOSE 80
EXPOSE 443
CMD ["/sbin/init"]
