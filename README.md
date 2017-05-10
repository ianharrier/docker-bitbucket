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

### Installing

1. Ensure the following are installed on your system:

    * [Docker](https://docs.docker.com/engine/installation/)
    * [Docker Compose](https://docs.docker.com/compose/install/#install-as-a-container)
    * `git`

2. Clone this repo to a location on your system. *Note: in all of the guides on this page, it is assumed the repo is cloned to `/srv/docker/bitbucket`.*

    ```shell
    sudo git clone https://github.com/ianharrier/docker-bitbucket.git /srv/docker/bitbucket
    ```

3. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

4. Create the `.env` file using `.env.template` as a template.

    ```shell
    sudo cp .env.template .env
    ```

5. Using a text editor, read the comments in the `.env` file, and make modifications to suit your environment.

    ```shell
    sudo vi .env
    ```

6. Start Bitbucket in the background.

    ```shell
    sudo docker-compose up -d
    ```

7. In a web browser, start the Bitbucket setup process by navigating to `http://<Docker-host-IP>:7990` (or whatever port you specified in the `.env` file).

8. Choose to setup Bitbucket using a **PostgreSQL** database, and use **db** as the database hostname. Use the database name, username, and password specified in the `.env` file.

### Upgrading

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Remove the current application stack.

    ```shell
    sudo docker-compose down
    ```

3. Pull any changes from the repo.

    ```shell
    sudo git pull
    ```

4. Backup the `.env` file.

    ```shell
    sudo mv .env backups/.env.old
    ```

5. Create a new `.env` file using `.env.template` as a template.

    ```shell
    sudo cp .env.template .env
    ```

6. Using a text editor, modify the new `.env` file. **Warning: it is especially important to use the same database name, username, and password as what exists in `backups/.env.old`.**

    ```shell
    sudo vi .env
    ```

7. Start Bitbucket in the background.

    ```shell
    sudo docker-compose up -d
    ```

8. When all is confirmed working, remove the the `.env.old` file.

    ```shell
    sudo rm backups/.env.old
    ```

### Running a one-time manual backup

**Warning: the backup process will put Bitbucket into maintenance mode, incurring a [usually brief] period of down time.**

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Run the backup script.

    ```shell
    sudo docker-compose exec backup app-backup
    ```

### Restoring from a backup

**Warning: the restoration process will immediately stop and delete the current production environment. You will not be asked to save any data before the restoration process starts.**

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Make sure the **backup** container is running. *Note: if the container is already running, you can skip this step, but it will not hurt to run it anyway.*

    ```shell
    sudo docker-compose up -d backup
    ```

3. List the available files in the `backups` directory.

    ```shell
    ls -l backups
    ```

4. Specify a file to restore in the following format:

    ```shell
    sudo docker-compose exec backup app-restore <backup-file-name>
    ```

    For example:

    ```shell
    sudo docker-compose exec backup app-restore 20170501T031500+0000.tar.gz
    ```

### Uninstalling

1. Set the working directory to the root of the repo.

    ```shell
    cd /srv/docker/bitbucket
    ```

2. Remove the application stack.

    ```shell
    sudo docker-compose down
    ```

3. Delete the repo. **Warning: this step is optional. If you delete the repo, all of your Bitbucket data, including backups, will be lost.**

    ```shell
    sudo rm -rf /srv/docker/jira
    ```
