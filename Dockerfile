FROM ubuntu:16.04

# Install Nginx + Nchan
RUN apt-get update
RUN apt-get -y install nginx

EXPOSE 80 443

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

CMD ["sh", "./start.sh"]
