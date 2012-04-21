
require 'resque'
require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" do
  require_relative '../lib/callfuture.me'
  ENV['QUEUE'] = '*'  # run all of the queues
  # Resque.schedule = YAML.load_file CallFutureMe.path('config/schedule.yml')
end

# desc "Alias for resque:work (To run workers on Heroku)"
# task "jobs:work" => "resque:work"
