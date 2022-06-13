first: database gems
	CONCURRENCY=200 NUM_REQUESTS=2000 SERVER=01-iterative.rb ./load-test.sh

second: database gems
	CONCURRENCY=50 NUM_REQUESTS=2000 SERVER=02-unbound-forking.rb ./load-test.sh

third: database gems
	CONCURRENCY=200 NUM_REQUESTS=2000 SERVER=03-preforking.rb ./load-test.sh

fourth: database gems
	CONCURRENCY=200 NUM_REQUESTS=2000 SERVER=04-threads.rb ./load-test.sh

fifth: database gems
	CONCURRENCY=200 NUM_REQUESTS=2000 SERVER=05-threads-single-database-connection.rb ./load-test.sh

sixth: database gems
	CONCURRENCY=200 NUM_REQUESTS=2000 SERVER=06-select-loop.rb ./load-test.sh

database: tools gems
	@-PGPASSWORD=ruby createdb -U ruby -h localhost -p 5432 ruby-concurrency "ruby concurrency tests"
	@-PGPASSWORD=ruby psql -U ruby -h localhost -p 5432 -d ruby-concurrency -f ./schema.sql

tools:
	@sh -c "which ab > /dev/null || brew install ab"
	@sh -c "which psql > /dev/null || brew install postgresql"

gems:
	bundle

.PHONY: first second third fourth fifth database tools gems