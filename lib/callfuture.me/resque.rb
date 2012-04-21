
require 'resque'
require 'resque_scheduler'
require 'resque/scheduler'

module CallFutureMe
  def self.redis
    @_redis ||= begin
      if production?
        uri = URI.parse(ENV["REDISTOGO_URL"])
        Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      else
        Redis.new(:host => 'localhost')
      end
    end
  end

  Resque.redis = redis
end
