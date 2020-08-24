#!/bin/sh
STATE=$1
DBNAME=$2
BACKUPNAME=$3
PASSWORD=$4
REMOTEUSER=$5
REMOTEIP=$6
STORAGEPATH=$7
RESTOREOPTIONS=$8

cd
touch ~/.ssh/known_hosts
chmod -R 600 .ssh/known_hosts
ssh-keygen -f ~/keys/id_rsa -y > ~/.ssh/id_rsa.pub
cp ~/keys/id_rsa ~/.ssh
chmod -R 600 ~/.ssh/id_rsa
ssh-keyscan -H $REMOTEIP >> ~/.ssh/known_hosts

# backup postgres db
if [ $STATE = "backup" ]; then
    DUMP_FILE_NAME="${BACKUPNAME}`date +%Y-%m-%d-%H-%M`.dump"
    echo "Creating dump: $DUMP_FILE_NAME"

    cd
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
    scp $DUMP_FILE_NAME.asc $REMOTEUSER@$REMOTEIP:$STORAGEPATH

    if [ $? -ne 0 ]; then
        echo "Back up could not be move to storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
        exit 1
    fi

    echo 'Successfully pushed to backup storage'
    exit 0
fi

# restore postgres db
if [ $STATE = "restore" ]; then
    echo "Pulling backup ${BACKUPNAME} from server"

    scp $REMOTEUSER@$REMOTEIP:$STORAGEPATH/$BACKUPNAME.asc ./
    
    if [ $? -ne 0 ]; then
        rm $DUMP_FILE_NAME.asc
        echo "Back up could not be pulled from storage, check scp connection to ${REMOTEUSER}@${$REMOTEIP}"
        exit 1
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
 echo "State option was not set correctly, see doc"
exit 1