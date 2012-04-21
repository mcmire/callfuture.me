
require 'logging'

module CallFutureMe
  module Logging
    def self.included(base)
      base.extend(self)
    end

    def logger
      @_logger ||= ::Logging.logger[self]
    end
  end

  include Logging

  log = ::Logging.logger.root
  if development?
    log.level = :debug
    log.add_appenders ::Logging.appenders.stdout
    log.add_appenders ::Logging.appenders.file('log/development.log')
  else
    log.level = :info
    log.add_appenders ::Logging.appenders.stdout
  end
end
