
require 'open-uri'

module CallFutureMe
  class Application < Sinatra::Base
    BASE_URL = production? ? 'http://callfutureme.heroku.com' : 'http://3qr8.localtunnel.com'

    register Jammit

    enable :sessions
    use Rack::Flash

    set :views, "app/views"

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
      Twilio.connect(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
      puts "Making call from #{TWILIO_CALLER_ID} to #{number} ..."
      resp = Twilio::Call.make(TWILIO_CALLER_ID, number, "#{BASE_URL}/answer")
      if exc = resp['TwilioResponse']['RestException']
        halt exc['Status'].to_i, exc['Message']
      else
        flash[:success] = "Request submitted, wait for your call."
        redirect "/"
      end
    end

    post '/answer/?' do
      begin
        verb = Twilio::Verb.new do |v|
          v.say "Thanks for using future dot me. After the beep, please record the message you'd like to send yourself."
          v.record(
            :action => "#{BASE_URL}/message",
            :playBeep => true
          )
        end
        verb.response
      rescue
        status 500
      end
    end

    post '/message/?' do
      begin
        # straight from the Ruby docs for Net::HTTP
        uri = URI.parse(params['RecordingUrl'] + '.mp3')
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request) do |resp|
            File.open('/tmp/recording.mp3', 'w') do |f|
              resp.read_body do |chunk|
                f.write(chunk)
              end
            end
          end
        end
        status 200
      rescue
        status 500
      end
    end
  end
end
