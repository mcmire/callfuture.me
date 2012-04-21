web: bin/rackup -s thin -p $PORT -E $RACK_ENV
queue: bin/rake resque:work
scheduler: bin/rake resque:scheduler
