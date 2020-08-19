FROM alpine

LABEL version="0.1" type="alpine-backup-retore"

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
RUN mkdir -p /home/backup/.ssh 
COPY --chown=backup:backup ./keys/* /home/backup/.ssh/
RUN chmod -R 600 /home/backup/.ssh/id_rsa && chmod -R 600 /home/backup/.ssh/known_hosts

CMD backup.sh $STATE $DBNAME $BACKUPNAME $PASSWORD $REMOTEUSER $REMOTEIP $STORAGEPATH $RESTOREOPTIONS