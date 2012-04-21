
require CallFutureMe.libpath('callfuture.me/application')

module CallFutureMe
  class Caller
    include Logging

    TwilioException = Class.new(StandardError)

    @queue = :worker

    def self.perform(number, epoch_seconds)
      time = Time.at(epoch_seconds).utc
      message = Message.create!(:recipient => number, :send_at => time)
      logger.debug "Persisted potential message (#{message.id}) to #{message.recipient} at #{message.send_at}"

      outgoing_number = CallFutureMe.twilio.outgoing_number
      url = Application.public_url("/answer")
      logger.debug "Making call from #{outgoing_number} to #{message.recipient} to record message..."
      logger.debug "(Twilio will POST to #{url})"
      data = Twilio::Call.make(outgoing_number, message.recipient, url)

      resp = data['TwilioResponse']
      if exc = resp['RestException']
        logger.info "Recording call could not be started?!"
        logger.info exc.inspect
        logger.debug "Removing message #{message.id}"
        message.destroy
        raise TwilioException, exc
      else
        message.call_sid = resp['Call']['Sid']
        message.save!
        logger.debug "Associated message to #{message.recipient} with call #{message.call_sid}"
      end
    end
  end
end

