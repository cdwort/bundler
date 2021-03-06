require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

class EndpointCredsDiffHost < Endpoint
  helpers do
    def auth
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
    end

    def authorized?
      auth.provided? && auth.basic? && auth.credentials && auth.credentials == %w[user pass]
    end

    def protected!
      unless authorized?
        response["WWW-Authenticate"] = %(Basic realm="Testing HTTP Auth")
        throw(:halt, [401, "Not authorized\n"])
      end
    end
  end

  before do
    protected! unless request.path_info.include?("/no/creds/")
  end

  get "/gems/:id" do
    redirect "http://diffhost.com/no/creds/#{params[:id]}"
  end

  get "/no/creds/:id" do
    if request.host.include?("diffhost") && !auth.provided?
      File.read("#{gem_repo1}/gems/#{params[:id]}")
    end
  end
end

Artifice.activate_with(EndpointCredsDiffHost)
