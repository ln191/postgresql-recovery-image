#!/bin/sh

cd
touch ~/.ssh/known_hosts
chmod -R 600 .ssh/known_hosts
ssh-keygen -f ~/keys/id_rsa -y > ~/.ssh/id_rsa.pub
cp ~/keys/id_rsa ~/.ssh
chmod -R 600 ~/.ssh/id_rsa
ssh-keyscan -H $REMOTEIP >> ~/.ssh/known_hosts

if [ "backup" = $STATE ]; then
    # backup postgres db

    DUMP_FILE_NAME="${BACKUPNAME}-$(date +$DATEFORMAT).dump"
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
    ssh $REMOTEUSER@$REMOTEIP mkdir $STORAGEPATH/$NAMESPACE/$BACKUPNAME
    scp $DUMP_FILE_NAME.asc $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$NAMESPACE/$BACKUPNAME

    if [ $? -ne 0 ]; then
        echo "Back up could not be move to storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
        exit 1
    fi

    echo 'Successfully pushed to backup storage'
    exit 0
fi

if ["restore" = $STATE]; then

    echo "Pulling backup ${BACKUPNAME} from server"
    if [-z "$BACKUPNAME"]; then
        echo "Pulling backup lastes backup from server"
        #  LATEST= ssh $REMOTEUSER@$REMOTEIP ls -t -l $STORAGEPATH/ | head -1

        echo "$LATEST"
        if [ $? -ne 0 ]; then
            echo "Back up could not be pulled from storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
            exit 1
        fi
    else
        echo "Pulling backup ${BACKUPNAME} from server"
        scp $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$BACKUPNAME.asc ./
        if [ $? -ne 0 ]; then
            echo "Back up could not be pulled from storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
            exit 1
        fi
    fi
    echo "Succesfully retrived Backup file"

    gpg --batch --passphrase $PASSWORD -o $BACKUPNAME -d $BACKUPNAME.asc

    echo "Succesfully decrypting Backup file"

    #psql --set ON_ERROR_STOP=on $DBNAME < $BACKUPNAME
    pg_restore $RESTOREOPTIONS -d $DBNAME $BACKUPNAME
    if [ $? -ne 0 ]; then
        echo "Error: Restoring of backup failed, check db connection settings"
        exit 1
    fi
    echo "Succesfully restoring ${DBNAME} from backup ${BACKUPNAME}"
    exit 0
fi
echo " invalid command STATE ENV must be set to backup or restore"
exit 1