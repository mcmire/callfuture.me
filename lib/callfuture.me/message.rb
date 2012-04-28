
module CallFutureMe
  class Message
    include Logging
    include MongoMapper::Document

    key :recipient_phone, String
    key :recipient_zip, String
    key :tz_offset, Integer
    key :call_sid, String
    key :time_recording_sid, String
    key :message_recording_sid, String
    key :send_at, Integer  # epoch seconds, or -1 or -2
    key :send_at_status, String  # 'ok', 'invalid', 'in_past', 'need_time', 'need_date'
    key :sent_at, Time
    timestamps!

    def recording_url
      Twilio.base_uri + "/Recordings/#{recording_sid}.mp3"
    end
  end
end
