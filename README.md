# docker-bitbucket

Dockerized Atlassian Bitbucket

### Contents

* [About](#about)
* [How-to guides](#how-to-guides)
    * [Installing](#installing)
    * [Upgrading](#upgrading)
    * [Running a one-time manual backup](#running-a-one-time-manual-backup)
    * [Restoring from a backup](#restoring-from-a-backup)
    * [Uninstalling](#uninstalling)

## About

This repo uses [Docker](https://www.docker.com) and [Docker Compose](https://docs.docker.com/compose/) to automate the deployment of [Atlassian Bitbucket](https://www.atlassian.com/software/bitbucket).

This is more than just a Bitbucket image. Included in this repo is everything you need to get Bitbucket up and running as quickly as possible and a **pre-configured backup and restoration solution** that is compliant with Atlassian's [production backup recommendations](https://confluence.atlassian.com/bitbucketserver/using-bitbucket-server-diy-backup-776640056.html).

## How-to guides

*Note: some of the commands in these guides may require root access to your system. If that is the case, either run the commands while logged in to the root account, or simulate a login to the root account using `sudo -i`. Due to the way environment variables are passed on some systems, typing `sudo` before each command is __not__ a supported method of running the commands in these guides with root access.*

### Installing

1. Ensure the following are installed on your system:

    * [Docker](https://docs.docker.com/engine/installation/)
    * [Docker Compose](https://docs.docker.com/compose/install/) **Warning: [installing as a container](https://docs.docker.com/compose/install/#install-as-a-container) is not supported.**
    * `git`

2. Clone this repo to a location on your system. *Note: in all of the guides on this page, it is assumed the repo is cloned to `/srv/docker/bitbucket`.*

    ```shell
    git clone https://github.com/ianharrier/docker-bitbucket.git /srv/docker/bitbucket
    ```

3. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

4. Create the `.env` file using `.env.template` as a template.

    ```shell
    cp .env.template .env
    ```

5. Using a text editor, read the comments in the `.env` file, and make modifications to suit your environment.

    ```shell
    vi .env
    ```

6. Start Bitbucket in the background.

    ```shell
    docker-compose up -d
    ```

7. In a web browser, start the Bitbucket setup process by navigating to `http://<Docker-host-IP>:7990` (or whatever port you specified in the `.env` file).

8. Choose to setup Bitbucket using a **PostgreSQL** database, and use **db** as the database hostname. Use the database name, username, and password specified in the `.env` file.

### Upgrading

**Warning: the upgrade process will immediately stop and upgrade the current production environment. The application stack will be unavailable while it is being upgraded.**

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/jira
    ```

2. Run the upgrade script.

    ```shell
    ./scripts/app-upgrade.sh
    ```

### Running a one-time manual backup

**Warning: the backup process will put Bitbucket into maintenance mode, incurring a [usually brief] period of down time.**

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Run the backup script.

    ```shell
    docker-compose exec backup app-backup
    ```

### Restoring from a backup

**Warning: the restoration process will immediately stop and delete the current production environment. You will not be asked to save any data before the restoration process starts.**

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Make sure the **backup** container is running. *Note: if the container is already running, you can skip this step, but it will not hurt to run it anyway.*

    ```shell
    docker-compose up -d backup
    ```

3. List the available files in the `backups` directory.

    ```shell
    ls -l backups
    ```

4. Specify a file to restore in the following format:

    ```shell
    docker-compose exec backup app-restore <backup-file-name>
    ```

    For example:

    ```shell
    docker-compose exec backup app-restore 20170501T031500+0000.tar.gz
    ```

### Uninstalling

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Remove the application stack.

    ```shell
    docker-compose down
    ```

3. Delete the repo. **Warning: this step is optional. If you delete the repo, all of your Bitbucket data, including backups, will be lost.**

    ```shell
    rm -rf /srv/docker/bitbucket
    ```
