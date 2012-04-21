
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

  if development?
    log = ::Logging.logger.root
    log.level = :debug
    log.add_appenders ::Logging.appenders.stdout
    log.add_appenders ::Logging.appenders.file('log/development.log')
  end
end
