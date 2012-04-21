source :rubygems

gem 'rake', '~> 0.9.2.0'
gem 'sinatra', '1.3.2'
gem 'thin', '1.3.1'
# gem 'jammit', :git => 'https://github.com/mcmire/jammit', :branch => 'fix_rails_assumptions'
gem 'jammit', :path => '~/code/github/forks/jammit'
gem 'jammit-sinatra', :git => 'https://github.com/mcmire/jammit-sinatra', :branch => 'middleware_only_dev'
# this is a version that works with rack 1.4
# see https://github.com/nakajima/rack-flash/issues/8
gem 'rack-flash3', '1.0.1'
gem 'twilio'

group :development do
  # http://www.twilio.com/engineering/2011/06/06/making-a-local-web-server-public-with-localtunnel/
  gem 'localtunnel'
  gem 'shotgun', '~> 0.9.0'
  gem 'coffee-script-source', '~> 1.2.0'
  # XXX: i forgot why we are using the git version?
  # gem 'guard', :git => "http://github.com/guard/guard"
  gem 'guard', '~> 1.0.0'
  gem 'guard-sass', '~> 0.6.0'
  gem 'guard-coffeescript', '~> 0.5.0'
  gem 'rb-fsevent', '~> 0.9.0'
  gem 'growl', '~> 1.0.0'
  gem 'heroku', '~> 2.24.0'
end
