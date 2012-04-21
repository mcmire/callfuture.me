
require_relative '../callfuture.me'

require 'open-uri'
require 'sinatra/base'
require 'jammit/sinatra'
require 'rack-flash'
require 'chronic'

module CallFutureMe
  class Application < Sinatra::Base
    include Logging

    def self.public_url(path="")
      base_url = CallFutureMe.production? ? 'http://callfutureme.herokuapp.com' : 'http://52dw.localtunnel.com'
      base_url + path
    end

    register Jammit

    enable :sessions
    use Rack::Flash

    set :views, "app/views"

    #---

    helpers do
      def stylesheet_link_tag(path, options={})
        fn = _resolve_path(path, 'stylesheets')
        bust = _get_bust(fn)
        %(<link rel="stylesheet" href="#{path}?#{bust}">\n)
      end

      def javascript_include_tag(path, options={})
        fn = _resolve_path(path, 'javascripts')
        bust = _get_bust(fn)
        %(<script src="#{path}?#{bust}"></script>\n)
      end
    end

    #---

    get "/?" do
      erb :index
    end

    post "/?" do
      number = params[:number] || ""
      if number.empty?
        flash[:error] = "You must enter a number."
        redirect "/"
        return
      end

      time = params[:time] || ""
      if time.empty?
        flash[:error] = "You must enter a time."
        redirect "/"
        return
      end
      time = Chronic.parse(time)
      if time.nil?
        flash[:error] = "You must enter a valid time."
        redirect "/"
        return
      elsif time < Time.now
        flash[:error] = "You must enter a time in the future."
        redirect "/"
        return
      end

      Resque.enqueue(Caller, number, time)
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

    # Twilio calls this when the user is actually leaving a recording
    post '/recording/?' do
      call_sid = params['CallSid']
      message = Message.find_by_call_sid!(call_sid)
      message.recording_sid = params['RecordingSid']
      message.save!
    end

    # Twilio calls this when the future job gets run and the recording
    # gets played
    get '/message/:id/?' do
      message_id = params['id']
      message = Message.find!(message_id)
      begin
        verb = Twilio::Verb.new do |v|
          v.play(message.recording_url)
        end
        verb.response
      rescue
        status 500
      end
      logger.debug "Message successfully played, setting sent_at"
      message.sent_at = Time.now
      message.save!
    end
  end
end

