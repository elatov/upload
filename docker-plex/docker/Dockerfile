FROM docker.io/centos:latest
COPY plex.sh /usr/bin/
COPY PlexMediaServer /etc/sysconfig/
RUN chmod +x /usr/bin/plex.sh
RUN groupadd -g 1000 plex
RUN useradd -u 1000 -g plex plex
ENTRYPOINT ["/usr/bin/plex.sh"]
