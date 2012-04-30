
require_relative '../callfuture.me'

require 'open-uri'
require 'sinatra/base'
require 'rack-flash'
require 'builder'

module CallFutureMe
  class Application < Sinatra::Base
    include Logging

    def self.public_url(path="")
      base_url = CallFutureMe.production? ? 'http://callfutureme.herokuapp.com' : 'http://52dw.localtunnel.com'
      base_url + path
    end

    enable :sessions
    use Rack::Flash

    set :views, "app/views"

    helpers do
      def input
        @tropo_input ||= Tropo::Generator.parse(request.env["rack.input"].read)
      end
    end

    #---

    # Twilio calls this when the user calls for the first time to leave a
    # recording
    post '/message.json' do
      session = input.session
      msg = Message.new(
        :tropo_session_id => session.id,
        :recipient_phone => session.from.id,
        :state => 1
      )
      msg.save!
      mid = msg.id

      tropo = Tropo::Generator.new do
        say :value => "Welcome to the messaging service for call future dot me."
        on :event => 'continue', :next => "/message/#{mid}/time_prompt.json"
      end
      resp = tropo.response
      puts resp
      resp
    end

    # Twilio calls this to play the prompt for the time
    post '/message/:mid/time_prompt.json' do
      mid = params['mid']
      pp :input => input
      result = input['result']

      return if result['state'] == 'DISCONNECTED'

      tropo = Tropo::Generator.new do
        disposition = (result['actions']['time']['disposition'] rescue "")
        message = case disposition
          when 'TIMEOUT'
            "Are you still there? If so, tell me when you'd like to receive your message. For example, tomorrow at five fifty four P M, or, ten minutes from now."
          else
            "To begin, tell me when you'd like to receive your message."
        end

        record \
          :name => 'time',
          :say => { :value => message },
          :timeout => 4,  # seconds
          :url => "/ok",  # this doesn't really matter
          :transcription => {
            :id => "time",
            :url => "/message/#{mid}/time_transcription"
          }

        on \
          :event => 'continue',
          :next => "/message/#{mid}/wait_for_time.json"
        # this will get hit for either nomatch or timeout
        on \
          :event => 'incomplete',
          :next => "/message/#{mid}/time_prompt.json"
      end
      resp = tropo.response
      puts resp
      resp
    end

    post '/message/:mid/time_transcription' do
      mid = params['mid']

      transcription = request.env['rack.input']
      pp :transcription => transcription

      msg = Message[mid]
      msg.transcription = transcription
      msg.save!

      status 200
    end

    post '/message/:mid/wait_for_time.json' do
      mid = params['mid']
      t = Time.now
      loop do
        if (Time.now - t) > 5000
          raise "Transcription never recorded?!"
        end
        msg = Message[mid]
        if msg.transcription.present?
          break
        end
        sleep 0.5
      end
      tropo = Tropo::Generator.new do
        say "Okay, time recorded. Looks like we're done here!"
        hangup
      end
      tropo.response
    end

=begin
    post '/message/:id/time_transcription.json' do
      mid = params['id']
      message = Message.find!(mid)
      time_str = params['TranscriptionText']
      epoch_seconds = nil
      time, status = TimeParser.parse(time_str)
      if time
        # Convert to UTC using client time zone
        # On Heroku, utc_time will == time
        # However, on our box, utc_time will be tz_offset BEHIND time
        utc_time = Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
        epoch_seconds = utc_time.to_i + message.tz_offset
        logger.debug "Epoch seconds is: #{epoch_seconds}"
        if epoch_seconds > Time.now.utc.to_i
          message.send_at = epoch_seconds
          message.send_at_status = 'ok'
        else
          message.send_at_status = 'in_past'
        end
      else
        # status is one of 'invalid', 'need_date', 'need_time'
        message.send_at_status = status
      end
      message.save!
    end

    # Twilio calls this to play the prompt for the message
    post '/message/:id/message_prompt.json' do
      mid = params['id']
      message = Message.find!(mid)
      verb = Twilio::Verb.new do |v|
        if params['repeat']
          v.say "Are you still there?"
          v.say "Just start talking to record your message."
        else
          v.say "That's all we need."
          v.say "Now start talking to record your message. You can hang up whenever you're done."
        end
        v.record :action => "/message/#{mid}/message"
        # if we end up here, the recording never happened
        v.redirect "/message/#{mid}/message_prompt?repeat=1"
      end
      verb.response
    end

    # Twilio calls this when the user has left a recording for the message
    post '/message/:id/message.json' do
      mid = params['id']
      message = Message.find!(mid)
      logger.debug "Persisting the sid for the message recording..."
      message.message_recording_sid = params['RecordingSid']
      message.save!

      logger.debug "Scheduling message to be sent in the future..."
      Resque.enqueue_at Time.at(message.send_at), Sender, message.id

      status 200
    end

    # Twilio calls this when the future job gets run and the recording
    # gets played
    post '/message/:id.json' do
      mid = params['id']
      message = Message.find!(mid)
      logger.debug "Message successfully played, setting sent_at"
      message.sent_at = Time.now
      message.save!
      begin
        verb = Twilio::Verb.new do |v|
          v.play(message.recording_url)
        end
        verb.response
      rescue => e
        logger.info "#{e.class}: #{e.message}"
        logger.info e.backtrace.join("\n")
        status 500
      end
    end

    post '/test_transcribe.json' do
      return if params['done']
      verb = Twilio::Verb.new do |v|
        v.say "Please say the message you'd like to transcribe."
        v.record \
          :action => '/transcribe?done=1',
          :transcribe => true,
          :transcribeCallback => '/test_transcription',
          :playBeep => true
      end
    end

    post '/test_transcription' do
      text = params['TranscriptionText']
      url = params['TranscriptionUrl']
      time = Time.now.to_f
      key = "test_transcription:#{time}"
      r = CallFutureMe.redis
      r.hset(key, 'text', text)
      r.hset(key, 'time', time)
      r.hset(key, 'url', url)
      status 200
    end
=end

    post '/ok' do
      status 200
    end
  end
end

