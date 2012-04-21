
APP_ROOT = File.expand_path('../..', __FILE__)
APP_ENV  = ENV['RACK_ENV'] || 'development'

require 'rubygems'
require 'pp'

# Set some constants so Jammit (and jammit-sinatra) don't get confused
ASSET_ROOT  = APP_ROOT
PUBLIC_ROOT = DEFAULT_PUBLIC_ROOT = File.join(APP_ROOT, 'public')
JAMMIT_ENV  = APP_ENV
require 'jammit'
Jammit.load_configuration File.join(APP_ROOT, 'config/assets.yml')

require 'sinatra/base'
require 'jammit/sinatra'
require 'rack-flash'

# require 'twilio-ruby'
require 'twilio'
TWILIO_ACCOUNT_SID = 'AC976defbafdd64ae1ba3857160a1100ac'
TWILIO_AUTH_TOKEN = '8010f86a12f4b639890f3d5323ba4f57'
TWILIO_CALLER_ID = '+1 415-599-2671'  # our sandbox number

require 'builder'
