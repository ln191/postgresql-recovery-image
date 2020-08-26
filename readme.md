# Backup and recovery image using dumps

ENV OPTIONS

|ENV        |Describtion                                    |Values             | required |
| ----      | --------                                      | ------            | -----   |
| STATE     | Should Image run backup or restore cmd        | backup or restore | Yes     |
| PGHOST    | The Host of the postgres db                   | service name or ip| Yes     |
| PGDATABASE| The Specific db name                          |                   | Yes     |
| PGUSER    | The postgres user to connect to db with       |                   | Yes     |
| PGPASSWORD| THe password for the postgres user            |                   | Yes     |
| PASSWORD  | The password to use for gpg symetric encryption | make strong     | Yes     |
| REMOTEUSER| The User used for ssh to storage server       | do not user root user | Yes   |
| REMOTEIP  | Ip of remote storage server                   |                   | Yes     |
| STORAGEPATH | root path where backup will be stored       |                   | Yes     |
| NAMESPACE | k8s namespace, use to create storage folder structure |                   | Yes     |
| DBAPP     | app name, use for naming of backup            |                   | Yes     |
| DATEFORMAT| set the date format used in backup naming     | "%Y-%m-%d-%H-%M"  | Backup: Yes |
| BACKUPFILE| File name of backup, which will be use to restore | ex: backup.dump.asc | Restore: Yes |






## Postgress sql dump



## tips

### no-cache
If you want to install something without caching things locally, which is recommended for keeping your containers small, include the --no-cache flag. Example:

    apk add --no-cache openssh

This is a small gain, it keeps you from having the common rm -rf /var/cache/apk/* at the end of your Dockerfile.

HOWEVER if you are adding a lot of packages it will have to pull the index files everytime you add a package.

so it would be better to start your docker file with apk update and end it with RUN rm -rf /var/cache/apk/* to clean the cache.

### non-root

One best practice when running a container is to launch the process with a non root user. This is usually done through the usage of the USER instruction in the Dockerfile