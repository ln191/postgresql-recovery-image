# Backup and recovery image using dumps

Change Date: 31-08-2020

Version: 1.1

## What does it do

This image can run the two following commands by setting STATE ENV:

- backup
  - Connect to postgres db and run sql_dump cmd to retrieve backup dump.
  - Encrypts sql_dump using gpg symmetric Aes 256 encryption.
  - Sends encrypted file to given server using scp.
- restore
  - Pull backup file from server using scp.
  - Decrypt file.
  - Connect to postgres db and run pg_restore cmd.

## ENV OPTIONS

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
| RESTOREOPTIONS | Pg_restore cmd options                   | ex: '-c'          | No      |

## Requirements

- Need to mount the private key that the image shall use for ssh connection, mountPath: /home/backup/keys
- Need to add the public key of the image to the backup servers authorized_keys file, to allow connection.

## Ref

Postgres Sql_dump:      https://www.postgresql.org/docs/12/backup-dump.html

gpg encryption:         https://tutonics.com/2012/11/gpg-encryption-guide-part-4-symmetric.html
                            https://www.tutorialspoint.com/unix_commands/gpg.htm

## tips

### shell script format error fix

Sometimes you may run into syntax error without there being any obvies error in the script, 

this may be because of the script is no longer in unix format. (do not know why it happen for me)

to fix this is get dos2unix linux tool and run it on the shell file and it will format it back to unix.

### no-cache

If you want to install something without caching things locally, which is recommended for keeping your containers small, include the --no-cache flag. Example:

    apk add --no-cache openssh

This is a small gain, it keeps you from having the common rm -rf /var/cache/apk/* at the end of your Dockerfile.

HOWEVER if you are adding a lot of packages it will have to pull the index files everytime you add a package.

so it would be better to start your docker file with apk update and end it with RUN rm -rf /var/cache/apk/* to clean the cache.

### non-root

One best practice when running a container is to launch the process with a non root user. This is usually done through the usage of the USER instruction in the Dockerfile.
