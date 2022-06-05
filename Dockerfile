FROM ruby:3.0.3

RUN apt-get update
RUN apt-get install -y net-tools time apache2-utils