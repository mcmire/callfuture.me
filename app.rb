
module CallFutureMe
  class Application < Sinatra::Base
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
      @message = flash[:success]
      erb :index
    end

    post "/?" do
      # make the Twilio call
      flash[:success] = "Request submitted, wait for your call."
      redirect "/"
    end
  end
end
