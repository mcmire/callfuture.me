
module CallFutureMe
  def self.environment
    @_environment ||= (ENV['RACK_ENV'] || 'development')
  end
  def self.development?
    environment == 'development'
  end
  def self.production?
    environment == 'production'
  end
end
