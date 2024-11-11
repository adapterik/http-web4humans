FROM docker.io/ruby:3.4.0-preview2-alpine3.20

# Add support for nio4r, a transitive dependency from puma
RUN apk update && apk upgrade --available && apk add build-base ruby-dev linux-headers make git nodejs npm openssh bash sqlite

# RUN apk update && apk upgrade --available && apk add build-base ruby-dev linux-headers make bash

# throw errors if Gemfile has been modified since Gemfile.lock
# RUN bundle config --global frozen 1
# RUN bundle update --bundler

# WORKDIR /usr/src/app
# COPY . .

# RUN bundle install

EXPOSE 3000

ENTRYPOINT ["bash", "-c"]
