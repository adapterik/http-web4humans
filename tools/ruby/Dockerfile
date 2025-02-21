FROM docker.io/ruby:3.4.2-alpine3.21

# Packages db must be updated first, add os dependencies
# required by Ruby gems (in this case just passenger)
RUN apk update && apk upgrade --available && apk add build-base ruby-dev linux-headers make bash sqlite git openssh

#EXPOSE 3000

ENTRYPOINT ["bash"]
