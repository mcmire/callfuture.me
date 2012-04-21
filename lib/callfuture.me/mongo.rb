
require 'mongo_mapper'

module CallFutureMe
  MongoMapper.config = {
    'development' => { 'uri' => 'mongodb://localhost/callfutureme' },
    'production'  => { 'uri' => ENV['MONGOHQ_URL'] }
  }
  MongoMapper.connect(environment)
end
