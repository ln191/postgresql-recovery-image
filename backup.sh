#!/bin/sh

cd
touch ~/.ssh/known_hosts
chmod -R 600 .ssh/known_hosts
ssh-keygen -f ~/keys/id_rsa -y > ~/.ssh/id_rsa.pub
cp ~/keys/id_rsa ~/.ssh
chmod -R 600 ~/.ssh/id_rsa
ssh-keyscan -H $REMOTEIP >> ~/.ssh/known_hosts

if [ "backup" = $STATE ]; then
    echo "Running Backup cmd..."
    # backup postgres db

    DUMP_FILE_NAME="${DBAPP}-$(date +$DATEFORMAT).dump"
    echo "time format: $(date +$DATEFORMAT)"
    echo "Creating dump: $DUMP_FILE_NAME"

    # dump sql db
    pg_dump -Fc $DBNAME > $DUMP_FILE_NAME

    if [ $? -ne 0 ]; then
        echo "Back up not created, check db connection settings"
        exit 1
    fi

    echo 'Successfully Backed Up'

    # sync encryption
    gpg --batch -c --passphrase $PASSWORD --armor --symmetric --cipher-algo AES256 $DUMP_FILE_NAME

    echo "Successfully Encrypted dump file: ${DUMP_FILE_NAME}"

    # move backup file
    ssh $REMOTEUSER@$REMOTEIP mkdir $STORAGEPATH/$NAMESPACE
    ssh $REMOTEUSER@$REMOTEIP mkdir $STORAGEPATH/$NAMESPACE/$DBAPP
    scp $DUMP_FILE_NAME.asc $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$NAMESPACE/$DBAPP

    if [ $? -ne 0 ]; then
        echo "Back up could not be move to storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
        exit 1
    fi

    echo 'Successfully pushed to backup storage'
    exit 0
fi

if [ "restore" = $STATE ]; then

    echo "Running Restore cmd..."
    if [ -z ${BACKUPFILE+x} ]; then
        echo "Pulling backup lastes backup from server"
        BACKUP=$( ssh $REMOTEUSER@$REMOTEIP ls -c $STORAGEPATH/$NAMESPACE/$DBAPP | head -1 )
        scp $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$NAMESPACE/$DBAPP/$BACKUP ./
       
        if [ $? -ne 0 ]; then
            echo "Back up could not be pulled from storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
            exit 1
        fi
        echo "Latest backup: $BACKUP"
    else
        echo "Pulling backup ${BACKUPFILE} from server"
        BACKUP=$BACKUPFILE
        scp $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$NAMESPACE/$DBAPP/$BACKUPFILE ./
        if [ $? -ne 0 ]; then
            echo "Back up could not be pulled from storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
            exit 1
        fi
    fi
    echo "Succesfully retrived Backup file"

    gpg --batch --passphrase $PASSWORD -o backup.dump -d $BACKUP

    echo "Succesfully decrypting Backup file"

    pg_restore $RESTOREOPTIONS -d $DBNAME backup.dump
    if [ $? -ne 0 ]; then
        echo "Error: Restoring of backup failed, check db connection settings"
        exit 1
    fi
    echo "Succesfully restoring ${DBNAME} from backup"
    exit 0
fi
echo " invalid command STATE ENV must be set to backup or restore"
exit 1