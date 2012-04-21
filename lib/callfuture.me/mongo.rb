
require 'mongo_mapper'

module CallFutureMe
  MongoMapper.config = {
    'development' => { 'uri' => 'mongodb://localhost' },
    'production'  => { 'uri' => ENV['MONGOHQ_URL'] }
  }
  MongoMapper.connect(environment)
  MongoMapper.database = 'callfutureme'
end
