web: bundle exec rackup config.ru -p $PORT
resque: env TERM_CHILD=1 bundle exec rake resque:workers QUEUE='*' COUNT='1'
