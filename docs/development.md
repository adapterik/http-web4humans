Start container and just shell into it:

```shell
DIR=`pwd` docker compose run --service-ports ruby
```

or

```shell
DIR="${PWD}" docker compose --file tools/ruby/docker-compose.yml run --rm --service-ports ruby
```

If the first time:

```shell
DIR="${PWD}" docker compose --file tools/ruby/docker-compose.yml build
```

Inside container prepare the ruby environment

```shell
bundle install
```

For house-cleaning purposes, it is nice to check for outdated dependencies:

```shell
bundle outdated
```

If this is the first time developing in this repo in this location, add an ssh key for this dev session

```shell
ssh-keygen -t ed25519 -C "erik@adaptations.com" -f /app/__local_only/github -N ""
eval "$(ssh-agent -s)"
ssh-add /app/__local_only/github
```

Then you need to visit the github repo and add the public key there.

now you can use git to push up changes.

then the cycle is

git add -A

git commit -m "your comment"

git push origin main


actually, first git will want you to fix it:

git config --global --add safe.directory /app
git config --global user.email "erik@adaptations.com"
git config --global user.name "Erik Pearson"

it takes less than a minute to build at github

then at sliplane, redeploy


Then start the dev server:

```shell
OWNER_PASSWORD="abc123" HOME_DIR=`pwd` bundle exec guard -i
```

To start the prod server, for instance to be able to set the port and other options directly:

```shell
OWNER_PASSWORD="abc123" HOME_DIR=`pwd` bundle exec puma  --port 3333 --no-config --workers 0
```