
require 'redis'

require 'ohm'
require 'ohm/contrib'

require 'resque'
require 'resque_scheduler'
require 'resque/scheduler'

module CallFutureMe
  class << self
    attr_accessor :redis
  end

  def self.redis_options
    case environment
    when 'production'
      uri = URI.parse(ENV["REDISTOGO_URL"])
      {:host => uri.host, :port => uri.port, :password => uri.password}
    when 'development'
      {:host => 'localhost'}
    when 'test'
      {:host => 'localhost', :db => 15}
    end
  end

  # Ohm doesn't provide a way to just set the Redis connection directly,
  # so use it to connect to Redis first and then grab that connection.
  Ohm.connect(redis_options)
  self.redis = Ohm.redis
  Resque.redis = self.redis
end
