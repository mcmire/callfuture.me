
require 'resque'
require 'resque/tasks'

task "resque:setup" do
  require_relative '../lib/callfuture.me'
  ENV['QUEUE'] = '*'
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
