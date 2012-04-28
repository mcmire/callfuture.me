
require_relative '../callfuture.me'

require 'open-uri'
require 'sinatra/base'
require 'rack-flash'
require 'chronic'

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

    #---

    get "/?" do
      @number = ""
      @time = ""
      erb :index
    end

    post "/?" do
      @number = params['number']
      @time   = params['time']

      number = @number || ""
      if number.empty?
        flash.now[:error] = "You must enter a number."
        return erb :index
      end

      # params['tz_offset'] is <offset in hours> * -1
      tz_offset = params['tz_offset'].to_i * 60

      Resque.enqueue(Caller, number, tz_offset)
      flash[:success] = "Okay, hang tight! We'll call you shortly so you can record the message."
      redirect "/"
    end

    # Twilio calls this when the user calls for the first time to leave a
    # recording
    post '/message/?' do
      message = Message.create! \
        :call_sid => params['CallSid'],
        :recipient_phone => params['From'],
        :recipient_zip => params['FromZip']
      message_id = message.id
      verb = Twilio::Verb.new do |v|
        # v.play Application.public_url("/audio/prompt.mp3")
        v.say "Welcome to the messaging service for call future dot me."
        v.redirect "/message/#{message_id}/time_prompt"
      end
      verb.response
    end

    # Twilio calls this to play the prompt for the time
    post '/message/:id/time_prompt/?' do
      message_id = params['id']
      message = Message.find!(message_id)
      verb = Twilio::Verb.new do |v|
        case params['time_status']
        when 'in_past'
          v.say "You need to give me a date in the future. Try it again."
        when 'need_date'
          v.say "You need to give me the date AND the time. Try it again."
        when 'need_time'
          v.say "You need to give me the time AND the date. Try it again."
        when 'invalid'
          v.say "I didn't recognize that date. Try again?"
        else
          if params['repeat']
            v.say "Are you still there?"
            v.say "If so, tell me when you'd like to receive your message."
            v.say "For example, tomorrow at five fifty four P M, or, ten minutes from now."
          else
            v.say "To begin, tell me when you'd like to receive your message."
          end
        end
        v.record \
          :action => "/message/#{message_id}/time",
          :transcribe => true,
          :transcribeCallback => "/message/#{message_id}/time_transcription"
        # if we end up here, the recording never happened
        v.redirect "/message/#{message}/time_prompt?repeat=1"
      end
      verb.response
    end

    # Twilio calls this when the user has left a recording for the time
    post '/message/:id/time/?' do
      message_id = params['id']
      message = Message.find!(message_id)
      logger.debug "Persisting the sid for the time recording..."
      message.time_recording_sid = params['RecordingSid']
      message.save!
      # Wait for the time recording to be transcribed
      t = Time.now
      send_at_status = nil
      loop do
        message.reload
        send_at_status = message.send_at_status
        break if send_at or (Time.now - t) > 5
        sleep 1
      end
      verb = Twilio::Verb.new do |v|
        case send_at_status
        when nil
          v.say "Oh dear. The time never got transcribed or something."
          v.say "There's nothing I can do here, so I'm leaving. Goodbye!"
          v.hangup
        when 'ok'
          v.redirect "/message/#{message_id}/message_prompt"
        else
          v.redirect "/message/#{message_id}/time_prompt?time_status=#{send_at_status}"
        end
      end
      verb.response
    end

    post '/message/:id/time_transcription/?' do
      message_id = params['id']
      message = Message.find!(message_id)
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
    post '/message/:id/message_prompt/?' do
      message_id = params['id']
      message = Message.find!(message_id)
      verb = Twilio::Verb.new do |v|
        if params['repeat']
          v.say "Are you still there?"
          v.say "Just start talking to record your message."
        else
          v.say "That's all we need."
          v.say "Now start talking to record your message. You can hang up whenever you're done."
        end
        v.record :action => "/message/#{message_id}/message"
        # if we end up here, the recording never happened
        v.redirect "/message/#{message_id}/message_prompt?repeat=1"
      end
      verb.response
    end

    # Twilio calls this when the user has left a recording for the message
    post '/message/:id/message/?' do
      message_id = params['id']
      message = Message.find!(message_id)
      logger.debug "Persisting the sid for the message recording..."
      message.message_recording_sid = params['RecordingSid']
      message.save!

      logger.debug "Scheduling message to be sent in the future..."
      Resque.enqueue_at Time.at(message.send_at), Sender, message.id

      status 200
    end

    # Twilio calls this when the future job gets run and the recording
    # gets played
    post '/message/:id/?' do
      message_id = params['id']
      message = Message.find!(message_id)
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

    post '/test_transcribe' do
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
  end
end

