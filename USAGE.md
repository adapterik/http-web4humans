# USAGE

In which we explain how to use the web4humans Tech site.

## Running and Developing Locally

### With Host Ruby

Developing the site on your local host environment is relatively straightforward, but I would recommend using the Docker-based workflow.

Still, if you would prefer this more light-weight but finicky approach, read on!

The web4humans Tech site has just two requirements:

- Ruby 3
- SQLite 3

Unless your system ships with Ruby 3 and SQLite 3, they will need to be installed.

I won't go into the details of these installations, other than to note that I use `macports`, and would accomplish this by:

```shell
sudo port install ruby3
sudo port install sqlite3
```

To setup and start the server:

```shell
bundle install
OWNER_PASSWORD=xxx HOME_DIR=`pwd` bundle exec puma
```

### Running and Developing with a devcontainer (Docker)

As mentioned above, the preferred way to develop the site is to do so with the Docker. The specific workflow utilizes a *devcontainer*. Since Visual Studio Code, at the time of writing, provides a stable, reliable devcontainer implementation, we will use it.

#### Requirements

- Visual Studio Code
- Docker

two optional helpers

- mkcert
- nss

##### Visual Studio Code

> TODO

#### Docker

At the time of writing, both Colima and Docker Destkop for macOS have been utilized and work very well. 

> TODO

#### mkcert & nss

> TODO


#### Starting the devcontainer

In order to work inside the devcontainer:

- open the repo folder in Visual Studio Code
- press they keys Control-Command-P to open the command palette, and search for "Dev Container: Open Folder in Devcontainer"
- the devcontainer images will be built, and the containers run
- VSC should drop you into the shell inside the devcontainer

at the container command line, enter:

```shell
bundle install # first time running server
OWNER_PASSWORD="xxx" HOME_DIR=`pwd` bundle exec guard -i
```

where `"xxx"` is the password you wish to use for the built-in owner account.

This will install all Ruby dependencies into the container (not on your host machine filesystem), and start the server.

You should be able to access the server now at `http://localhost:3000`.

For example:

```shell
OWNER_PASSWORD=abc123 ./Taskfile start-dev-server
```

#### Using "real" hostname

The production site is available at `https://tech.web4humans.com`. In order to utilize the site on this host, see below:

Install dependencies onto your host:

- mkcert
- nss

With macports:

```
sudo port install mkcert
sudo port install nss
```

Install the development certificates with:

```shell
./tools/proxy/make-dev-cert.sh
```

Set the host in `/etc/hosts`, adding the line:

```text
127.0.0.1   tech.web4humans.com
```

You should now be able to access the local site at

```url
https://tech.web4humans.com
```

Don't forget to comment out the new `/etc/hosts` line if you want to access the production site.

