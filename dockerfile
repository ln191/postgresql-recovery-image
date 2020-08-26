FROM alpine

LABEL version="1.0" type="alpine-backup-retore"

RUN apk update
RUN apk upgrade
RUN apk add postgresql
RUN apk add openssh
RUN apk add gnupg
RUN rm -rf /var/cache/apk/*

COPY backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup.sh

RUN addgroup -S backup && adduser -S backup -G backup

USER backup
RUN mkdir -p ~/.ssh && mkdir ~/keys

CMD backup.sh