
require 'open-uri'
require 'sinatra/base'
require 'jammit/sinatra'
require 'rack-flash'

module CallFutureMe
  class Application < Sinatra::Base
    def self.public_url(path="")
      base_url = CallFutureMe.production? ? 'http://callfutureme.heroku.com' : 'http://3qr8.localtunnel.com'
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
      end

      Resque.enqueue(Caller, number, time)
      flash[:success] = "Okay, hang tight! We'll call you shortly so you can record the message."
      redirect "/"
    end

    post '/answer/?' do
      begin
        verb = Twilio::Verb.new do |v|
          v.play Application.public_url("/audio/prompt.mp3")
          v.record(
            :action => Application.public_url("/nonexistent"),
            :playBeep => true
          )
        end
        verb.response
      rescue
        status 500
      end
    end
  end
end

