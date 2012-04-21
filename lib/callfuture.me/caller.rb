
require CallFutureMe.libpath('callfuture.me/application')

module CallFutureMe
  class Caller
    include Logging

    TwilioException = Class.new(StandardError)

    @queue = :worker

    def self.perform(number, time)
      message = Message.create!(:recipient => number, :send_at => time)
      logger.debug "Persisted potential message (#{message.id}) to #{message.recipient} at #{message.send_at}"

      our_number = CallFutureMe.twilio.our_number
      url = Application.public_url("/answer")
      logger.debug "Making call from #{our_number} to #{number} to record message..."
      logger.debug "(Twilio will POST to #{url})"
      data = Twilio::Call.make(our_number, number, url)

      resp = data['TwilioResponse']
      if exc = resp['RestException']
        logger.debug "Recording call could not be started?! Removing message #{message.id}"
        message.destroy
        raise TwilioException, exc
      else
        message.call_sid = resp['Call']['Sid']
        message.save!
        logger.debug "Associated message to #{message.recipient} with call #{message.call_sid}"
        logger.debug "Scheduling message to be sent in the future..."
        Resque.enqueue_at message.send_at, Sender, message.id
      end
    end
  end
end

