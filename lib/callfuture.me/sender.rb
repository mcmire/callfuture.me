
require CallFutureMe.libpath('callfuture.me/application')

module CallFutureMe
  class Sender
    include Logging

    @queue = :schedule

    def self.perform(message_id)
      message = Message.find!(message_id)
      url = Application.public_url("/message/#{message_id}")
      outgoing_number = CallFutureMe.twilio.outgoing_number
      logger.debug "Making call from #{outgoing_number} to #{message.recipient} to play message..."
      logger.debug "(Twilio will POST to #{url})"
      data = Twilio::Call.make(outgoing_number, message.recipient, url)
      resp = data['TwilioResponse']
      if exc = resp['RestException']
        logger.info "Message call could not be started?!"
        logger.info exc.inspect
        raise TwilioException, exc
      end
    end
  end
end
