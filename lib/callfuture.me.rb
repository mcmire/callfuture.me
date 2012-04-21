
require 'pp'
require 'ostruct'

require 'twilio'
require 'resque'
require 'mongo_mapper'
require 'chronic'
require 'logging'

include Logging.globally

module CallFutureMe
  def self.twilio
    @_twilio ||= OpenStruct.new
  end

  def self.path
    File.expand_path('../..', __FILE__)
  end

  def self.environment
    @_environment ||= (ENV['RACK_ENV'] || 'development')
  end
  def self.development?
    environment == 'development'
  end
  def self.production?
    environment == 'production'
  end

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

  twilio.account_sid = 'AC976defbafdd64ae1ba3857160a1100ac'
  twilio.auth_token  = '8010f86a12f4b639890f3d5323ba4f57'
  twilio.our_number  = '+1 415-599-2671'  # our sandbox number
  Twilio.connect(twilio.account_sid, twilio.auth_token)

  Resque.redis = redis

  MongoMapper.config = {
    'development' => { 'uri' => 'mongodb://localhost' },
    'production'  => { 'uri' => ENV['MONGOHQ_URL'] }
  }
  MongoMapper.connect(environment)
  MongoMapper.database = 'callfutureme'

  if development?
    log = Logging.logger.root
    log.level = :debug
    log.add_appenders Logging.appenders.stdout
    log.add_appenders Logging.appenders.file('log/development.log')
  end
end

# Set some constants so Jammit (and jammit-sinatra) don't get confused
ASSET_ROOT  = CallFutureMe.path
PUBLIC_ROOT = DEFAULT_PUBLIC_ROOT = File.join(CallFutureMe.path, 'public')
JAMMIT_ENV  = CallFutureMe.environment
require 'jammit'
Jammit.load_configuration File.join(CallFutureMe.path, 'config/assets.yml')

require_relative 'callfuture.me/caller'
require_relative 'callfuture.me/message'
require_relative 'callfuture.me/application'
