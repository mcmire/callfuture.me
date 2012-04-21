
require File.expand_path('../lib/callfuture.me/application', __FILE__)

require 'resque/server'
require 'resque_scheduler/server'

use Rack::Static, :urls => %w(/audio), :root => 'public'

run Rack::URLMap.new \
  "/"       => CallFutureMe::Application,
  "/resque" => Resque::Server.new
