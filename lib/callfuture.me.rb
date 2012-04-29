
require 'pp'  # for development purposes

require_relative 'callfuture.me/paths'

module CallFutureMe
  require libpath('callfuture.me/environment')
  require libpath('callfuture.me/logging')

  require libpath('callfuture.me/redis')
  require libpath('callfuture.me/tropo')

  require libpath('callfuture.me/message')
  require libpath('callfuture.me/caller')
  require libpath('callfuture.me/sender')
end
