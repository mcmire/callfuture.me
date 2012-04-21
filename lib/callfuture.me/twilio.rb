
require 'ostruct'
require 'twilio'

module CallFutureMe
  def self.twilio
    @_twilio ||= OpenStruct.new
  end

  twilio.account_sid     = ENV['TWILIO_ACCOUNT_SID']
  twilio.auth_token      = ENV['TWILIO_AUTH_TOKEN']
  twilio.outgoing_number = ENV['TWILIO_OUTGOING_NUMBER']
  Twilio.connect(twilio.account_sid, twilio.auth_token)
end
