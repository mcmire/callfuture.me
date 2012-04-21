
module CallFutureMe
  class Message
    include Logging
    include MongoMapper::Document

    key :recipient, String, :required => true
    key :send_at, Time, :required => true
    key :call_sid, String
    key :recording_sid, String
    key :sent_at, Time
    timestamps!

    def recording_url
      Twilio.base_uri + "/Calls/#{call_sid}/Recordings/#{recording_sid}.mp3"
    end
  end
end
