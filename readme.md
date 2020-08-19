# Backup and recovery image using dumps



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