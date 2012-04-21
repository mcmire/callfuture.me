
module CallFutureMe
  class Message
    include MongoMapper::Document

    key :request_call_sid, String, :required => true
    key :request_call_uri, String, :required => true
    key :recipient, String, :required => true
    key :send_at, Time, :required => true
    timestamps!

    def self.store!(call, time)
      create!(
        :request_call_sid => call['Sid'],
        :request_call_uri => call['Uri'],
        :recipient => call['To'],
        :send_at => time
      )
    end
  end
end
