ARG ALPINE_TAG=latest

FROM alpine:$ALPINE_TAG

RUN apk add -U kodi-gbm intel-media-driver libva-intel-driver libxslt mesa-dri-gallium tzdata

ARG KODI_UID=1000
ARG KODI_GID=1000
ARG AUDIO_GID=29
ARG VIDEO_GID=44
ARG RENDER_GID=107

RUN sed -i -r -e "/^kodi:/s/:\d+:\d+:/:$KODI_UID:$KODI_GID:/;" \
              -e '/^kodi:/s:/sbin/nologin:/bin/sh:' \
              /etc/passwd

RUN sed -i -r -e "/^kodi:/s/:\d+:/:$KODI_GID:/" \
              -e "/^audio:/s/:\d+:/:$AUDIO_GID:/" \
              -e "/^video:/s/:\d+:/:$VIDEO_GID:/" \
              /etc/group

RUN addgroup kodi audio
RUN addgroup kodi video
RUN addgroup -g $RENDER_GID render
RUN addgroup kodi render
RUN chown kodi /var/lib/kodi
RUN chgrp kodi /var/lib/kodi

COPY settings.xsl /root
RUN mv /usr/share/kodi/system/settings/settings.xml /usr/share/kodi/system/settings/settings.bak
RUN xsltproc -o /usr/share/kodi/system/settings/settings.xml /root/settings.xsl /usr/share/kodi/system/settings/settings.bak

EXPOSE 8080 9090 9777/udp

USER kodi
WORKDIR /var/lib/kodi
ENTRYPOINT [ "/usr/bin/kodi-gbm" ]
