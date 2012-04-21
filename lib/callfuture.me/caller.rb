
module CallFutureMe
  class Caller
    TwilioException = Class.new(StandardError)

    @queue = :core

    def self.perform(number, time)
      our_number = CallFutureMe.twilio.our_number
      logger.info "Making call from #{our_number} to #{number}..."
      data = Twilio::Call.make(our_number, number, Application.public_url("/answer"))
      resp = data['TwilioResponse']
      if exc = resp['RestException']
        raise TwilioException, exc
      else
        Message.store!(resp['Call'], time)
      end
    end
  end
end

