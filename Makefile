first: setup
	CONCURRENCY=100 NUM_REQUESTS=3000 SOCKET_BACKLOG_LEN=1024 SERVER=01-iterative ./load-test.sh

second: setup
	CONCURRENCY=100 NUM_REQUESTS=3000 SOCKET_BACKLOG_LEN=1024 SERVER=02-unbounded-forking ./load-test.sh

third: setup
	CONCURRENCY=100 NUM_REQUESTS=3000 SOCKET_BACKLOG_LEN=1024 SERVER=03-preforking ./load-test.sh

fourth: setup
	CONCURRENCY=100 NUM_REQUESTS=3000 SOCKET_BACKLOG_LEN=1024 SERVER=04-threads ./load-test.sh

setup:
	@-PGPASSWORD=ruby createdb -U ruby -h localhost -p 5432 ruby-concurrency "ruby concurrency tests"
	@-PGPASSWORD=ruby psql -U ruby -h localhost -p 5432 -d ruby-concurrency -f ./schema.sql

.PHONY: first second third fourth setup