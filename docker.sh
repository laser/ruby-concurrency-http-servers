#!/bin/bash

docker build . -t ruby-concurrency-http-servers:latest

docker run -it -v $PWD:/var/opt/whatever ruby-concurrency-http-servers /bin/bash