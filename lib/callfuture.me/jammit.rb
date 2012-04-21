
# Set some constants so Jammit (and jammit-sinatra) don't get confused
ASSET_ROOT  = CallFutureMe.path
PUBLIC_ROOT = DEFAULT_PUBLIC_ROOT = File.join(CallFutureMe.path, 'public')
JAMMIT_ENV  = CallFutureMe.environment
require 'jammit'
Jammit.load_configuration File.join(CallFutureMe.path, 'config/assets.yml')
