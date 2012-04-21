
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
      @number =
        self.class.development? ?
          "+1 615-973-8052" :
          ""
      @time =
        self.class.development? ?
          (Time.now + 60).strftime("%-m/%-d/%Y at %-I:%M%P") :
          ""
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

      time = @time || ""
      if time.empty?
        flash.now[:error] = "You must enter a time."
        return erb :index
      end
      time = Chronic.parse(time)
      if time.nil?
        flash.now[:error] = "You must enter a valid time."
        return erb :index
      else
        # convert to UTC using client time zone
        # on Heroku, utc_time will == time
        # however, on our box, utc_time will be tz_offset BEHIND time
        utc_time = Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
        # params['tz_offset'] is (offset in hours) 8 -1
        tz_offset = params['tz_offset'].to_i * 60
        epoch_seconds = utc_time.to_i + tz_offset
        logger.debug "Epoch seconds is: #{epoch_seconds}"
        if epoch_seconds < Time.now.utc.to_i
          flash.now[:error] = "You must enter a time in the future."
        return erb :index
        end
      end

      Resque.enqueue(Caller, number, epoch_seconds)
      flash[:success] = "Okay, hang tight! We'll call you shortly so you can record the message."
      redirect "/"
    end

    # Twilio calls this when the user calls for the first time to leave a
    # recording
    post '/answer/?' do
      begin
        verb = Twilio::Verb.new do |v|
          # v.play Application.public_url("/audio/prompt.mp3")
          v.say "Please leave your message after the beep."
          v.record(
            :action => Application.public_url("/recording"),
            :playBeep => true
          )
        end
        verb.response
      rescue
        status 500
      end
    end

    # Twilio calls this when the user has left a recording
    post '/recording/?' do
      call_sid = params['CallSid']
      message = Message.find_by_call_sid!(call_sid)
      message.recording_sid = params['RecordingSid']
      message.save!
      logger.debug "Scheduling message to be sent in the future..."
      Resque.enqueue_at message.send_at, Sender, message.id
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
      rescue
        status 500
      end
    end
  end
end

