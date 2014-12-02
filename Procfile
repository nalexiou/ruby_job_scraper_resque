web: bundle exec rackup config.ru -p $PORT
resque: env TERM_CHILD=1 bundle exec rake resque:workers QUEUE='*' COUNT='1'
resque: env TERM_CHILD=1 RESQUE_TERM_TIMEOUT=8 COUNT=2 bundle exec rake resque:workers
