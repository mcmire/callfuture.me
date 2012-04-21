
require 'ostruct'
require 'twilio'

module CallFutureMe
  def self.twilio
    @_twilio ||= OpenStruct.new
  end

  twilio.account_sid = 'AC976defbafdd64ae1ba3857160a1100ac'
  twilio.auth_token  = '8010f86a12f4b639890f3d5323ba4f57'
  twilio.our_number  = '+1 720-583-4813'
  Twilio.connect(twilio.account_sid, twilio.auth_token)
end
