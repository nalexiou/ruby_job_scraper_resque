web: bundle exec rackup config.ru -p $PORT
resque: env TERM_CHILD=1 RESQUE_TERM_TIMEOUT=8 COUNT=3 bundle exec rake resque:workers
