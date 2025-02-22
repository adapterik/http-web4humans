# Deploying and Hosting with Dokku at Digital Ocean

## About

I have a web site project which is required to operate under both http and https endpoints. 

The reason "why" is not really relevant to this document, but when I've chased this down on the web, the rare developer attempting this is often challenged with the "but why on Earth?" question.

So...

### Why on Earth?

Imagine a world in which the web evolves quickly, from informational and fun to serious and commercial. Older web browsers were designed for the prior, and current browsers for the latter. As part of the security lockdown in the serious age, web access now assumes encryption of a high level.

But older computers and browsers were not designed for this world, and are excluded from it.

But so much content from the past and present can happily live uin a world without encryption. It is decoupled from any personal information, sensitive services, ecommerce and so forth.

I have a small project to create a site dedicated to providing information and services that will work fine with older browsers and systems. This necessitates that the site operate over plain `http:`, without the `s`, that is, without encryption.

The site goes into many considerations of this project, so I'll just leave it here.

### This document

This document describes how I set up this system to run in the open web.

The constraints are:

- operate over http and https
- no automatic eforcement of https
- run web site in a docker container

Surprisingly, to me at least, there are few services satisfying these constraints! In the modern era, https is considered such a de facto requriement that most services do not offer even an option to enable http. The only service I could use was Microsoft Azure. 

Nothing against Azure itself (other than amazing complexity and abundance of options) - but I am steadfast in my rebellion against consolidation of computing resources into the few mega corporations currently dominating our world.

It ends up that there are (and have been for a while, I was just blissfully unaware) services which make deployment of docker containers relatively straightforward. I chose `dokku`, without a thorough review of all options, because it fit the bill. It has a well-documented command line interface, an optional gui, and is supported directly by one of the cloud services I currently use - Digital Ocean.

So this document describes how I set up my little site in dokku at Digital Ocean.

## How To

Digial Ocean has a "1-click" add-on to a "Droplet" - a virtual machine instance - ready to go after, well, a few clicks.

Here is how I set it up:


### Create the droplet

Use the Digital Ocean interface to create a droplet.  

- Log In
- Select the project from PROJECTS on the left side panel
- From the horizontal menu click the "Create ^" menu
- Select "Droplets" from the dropdown menu
- Select the appropriate Region, Datacenter
- In the "Choose an Image" section select the "Marketplace..." tab
- Search for "dokku"
- Select the "Dokku" image
- Select the plan that best suits you - I started with Basic.
- Select the CPU options that best suits you - I selected the 12/mo one since dokku will need to launch processes to manage itself while containers are running providing web services!
- In the "Choose Authentication Method" section select "SSH Key". If you don't have a key for your current host development machine, you should open a new window and add an SSH key to your project (not covered here)
- Chooser the SSH key for your current dev machine.
- Create your droplet!


> Hope I didn't leave anything off - at some point should create a droplet from scratch and run through all these instructions to make sure they are precisely correct.

### Log into your dokku container

All of the operations below will be using the `dokku` command as the root user of the container. 

In order to accomplish this we'll need to ssh into our service.

You can get the hostname for your service from the DO interface.

Oh, wait, there is no hostname yet!

- Create hostname mapping for your new DO droplet.
  
  You'll notice that the drop does not have a default hostname. If you created a DO app, you will have a weird default hostname, but not for plain droplets.

- Get the ip address for the droplet

  Navigate to the droplet in the DO web interface. Note that in the header for this page, below the drop let id, is a label "ipv4:", to the right of which is the ip address for the droplet.

- Add an "A" DNS record

  In the DNS managment tool for the domain in which the web site's hostname will reside, add an "A" DNS record, utilizing the IPv4 address displayed.


- Log into the app via ssh:

  From your local dev host:

  ```shell
  ssh root@HOSTNAME
  ```

  Where `HOSTNAME` is the host name added in the DNS record above.


You should now be resting at a terminal prompt, something like this:

```shell
root@dokku0306onubuntu2204-s-1vcpu-1gb-sfo3-01:
```


###  Set up dokku

- Set required environment variables, if required

  Your web app may require environment variables. If so, you will need to set them at some point, so might as well do it first thing.


  Below is how we can set up the environment variables for our app.

  ```shell
  dokku config:set http-web4humans OWNER_PASSWORD=xxxxxx WORKERS=0
  ``` 

- Specify internal port

  Whan I first read the DO dokku docs, I read that the docker container MUST utilize a `PORT` environment variable to set the port to which the contianer will listen.

  This actually worked the first time I set it up. However, after some set of operations (perhaps starting the SSL configuration below?), dokku, or rather the container, complained that `PORT` was not set. 

  Although confused, I went ahead and set it like so:

  ```shell
  dokku config:set http-web4humans PORT=3000 
  ``` 

  Now, it ends up that this is not necessary. Rather, you can set the `EXPOSE` option within the project's Dockerfile. Dokku will use the value of `EXPOSE`.

  This would make everything a bit simpler, as the `PORT` environment variable needs to be implemented within `tools/entrypoint.sh` in order to provide it to docker when running the container.


### Set up SSL

- Install the letsencrypt plugin

  ```shell
  dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
  ```


- Set the contact email

  letsencrypt integration requires your email address in order to register for and receive a certificate. (It also requries a valid DNS-locatable hostname, which is described below.)

  ```shell
  dokku letsencrypt:set http-web4humans email erik@adaptations.com
  ``` 

- Correct the global domain

  Dokku creates a default nonsensical "default global domain". It is used to create a hostname (aka domain) for an app by prepending the app name, a dot, and the global domain, to create the app hostname (domain).

  Seems like a strange assumption, but there you to.

  Ot fix the strange default global domain name

  ```shell
  dokku domains:set-global web4humans.com
  ```

  We won't actually use this yet, but it is nice to have it be correct.

  Note that this feature assumes all "sites" (there is no guarantee that an app is a web site at all) or subdomains of this. 

- Remove automatic hostname

  Dokku creates a hostname automatically, we need to remove it because it is not real and will confuse the letsencrypt plugin

  First, we need to determine the hostname:
  ```shell
  dokku domains:report http-web4humans
  ```

  This will product a list of hostnames

  ... not shown yet, need to find it in the terminal or generate it fresh...

  Then remove the hostname

  ```shell
  dokku domains:remove http-web4humans http-web4humans.packer-6481b5fa-f32f-c6ab-b44d-a2621ac2dcee
  ``` 

- Enable letsencrypt

  ```shell
  dokku letsencrypt:enable http-web4humans
  ```
- Ensure SSL certs are renewed in a timely manner

  Remember the old days where you had to remember to get a new cert every year or three and place it into the correct place in the site directory tree and restart the server? Well, with letsencrypt those days are over...

  ```shell
  dokku letsencrypt:cron-job --add
  ```

### Configure nginx template


### Configure nginx proxy

By default dokku sets up the container proxy to prefer https if an ssl certificate is installed. However, we want to have http and https fully under control of our web app.

This requires disabling two features that are enabled by default.

The first and most primitive is the nginx proxy configuration itself, which performs a 301 redirect to the https endpoint if invoked on port 80. dokku uses a templating system to generate the nginx config file for an app. The templating system is "sigil", based on golang templates. Unfortunately, the bit of the template that generates the 301 redirect stanza is not configurable. Well, it is configurable in that it detects if SSL is installed, and if so, generates the server stanza to perform the redirect for port 80. However, it does not have any user-configurable variable to disable/enable that behavior.

The only recourse is to alter the nginx template itself. Fortunately, dokku provides a way of providing the template directly. This allows all sorts of shenanigans, which unfortunately is a pretty glaring footgun. I'll get to the future problems this introduces below.

In our app we have configured dokku to deply a pre-built image from a registry. In order to supply a "custom nginx template", we need to place a copy of a compatible template in the "WORKDIR" specified in our Dockerfile. For us, this is the installation directory for our web app in the resulting image. We accomplish this by copying the nginx config file from the dokku repo, placing this in the root of our web app repo, making the alterations we need, pushing these changes up to our remote, and then redeploying our dokku app with the newly tagged image.

Here are the steps:

- Determine the version of dokku in the Digital Ocean droplet.

   - ssh into the droplet
   - issue the command
     ```shell
     dokku version
     ```

- Visit the dokku repo at github

- Navigate to the version indicated above

- Navigate to the template

- View the template in raw mode

- In your local project repo, create a file at the project root named `nginx.conf.sigil`

- Open the file for editing

- Back in the raw view of the template in the dokku github repo browser window, select all the text, copy it, and paste it into the new template file in your local project.

- Save the local template file.

- Locate the section in the template file which generates the 301. In the version I'm working with, 30.7, this is on line 15. 

```text
{{ if (and (eq $listen_port "80") ($.SSL_INUSE)) }}
  include {{ $.DOKKU_ROOT }}/{{ $.APP }}/nginx.conf.d/*.conf;
  location / {
    return 301 https://$host:{{ $.PROXY_SSL_PORT }}$request_uri;
  }
{{ else }}
```

Note that the first line is a conditional, which causes the enclosed content to be output if the port is 80.

To understand this requires reading the whole template file. If the app is configured for an "http" unencrypted connection, then if it is configured with a port 80 and it is configured for SSL, the redirect will be emitted, otherwise a regular server section will be generated to serve up the app on http.

This implies that one can set up an http endpoint that is not port 80 and avoid the redirect entirely. That is not our case, however, as we need the natural port 80 to work.

We need to avoid the redirect section being emitted. We could simply remove the conditional altogether. However, for the sake of brevity (and configurability), we elect to rather place an additional value in the conditional expression. The condition is controlled by an `and` expression, so all we need is to make sure it evaluates to false. 

The templating system is `sigil`, which is essentially a golang text template with some custom functionality. Knowing this, we can see that the `and` expression considers any empty string to be false. In fact, that is all it does!

So we create this false/empty string by using an environment variable `REDIRECT_HTTP`. The way to use a dokku environment variable is with the `var` command from `sigil`. It will evaluate to the empty string if the indicated environment variable is missing or has the empty string as a value.

By adding this conditional to the expression, and since it is not already set, we have essentially disabled the generation of the redirect!

```text
{{ if (and (eq $listen_port "80") ($.SSL_INUSE) (var "REDIRECT_HTTP")) }}
```

We may eventually change this to be a positive comparison to a value rather than using the empty string:

```text
{{ if (and (eq $listen_port "80") ($.SSL_INUSE) (eq (var "REDIRECT_HTTP") "yes") }}
```

### Disable HSTS via the nginx config

Well, after disabling the 301 redirect, I found that there is a second measure in place - the HSTS header.

The `Strict-Transport-Security` header is not controlled by the primary nginx template, but fortunately it is controlled by an nginx proxy configuration setting `hsts-max-age`.

Frankly, the redirect should be similarly controlled.

- Ensure HSTS is disabled

```shell
dokku nginx:set http-web4humans hsts-max-age 0
```

Note that we can also do

```shell
dokku nginx:set http-web4humans hsts false`
```

but the first technique ensures that any browsers that have already been redirected have HSTS disabled upon the next connection; otherwise, it will persist in the browser until the timeout expires.

- Rebuild the config:

```shell  
dokku proxy:build-config http-web4humans
```

### Deploying and redeploying

  Deploying for the first time, and redeploying, is composed of the following:


  ```shell
  dokku git:from-image http-web4humans ghcr.io/adapterik/http-web4humans:main_2025-02-21t16-40-43
  ```

  where the tag is `main_DATE`, where `DATE` is the build date as placed on the image tag in the GHA workflow.

  Dokku will cache the image locally, in the VM, and will generally reuse the image unless the tag specified above does not match one locally cached.

  So the general strategy is that when an image is created and stored in an external registry, it must get a new tag if you want to deploy it.

  You can use whatever strategy you like, but we are using a date+time stamp. Of course, a semver 2.0 tag is also very common when one has a more formal release process.
