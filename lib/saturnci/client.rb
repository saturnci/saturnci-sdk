require "json"
require "net/http"
require "uri"

module SaturnCI
  class Client
    def initialize(user_id: nil, api_token: nil, base_url: "https://app.saturnci.com")
      credentials = if user_id && api_token
        { "user_id" => user_id, "api_token" => api_token }
      else
        JSON.parse(File.read(File.expand_path("~/.saturnci/credentials.json")))
      end

      @user_id = credentials["user_id"]
      @api_token = credentials["api_token"]
      @base_url = base_url
    end

    def get(path)
      request(:get, path)
    end

    def post(path, params = {})
      request(:post, path, params)
    end

    private

    def request(method, path, params = nil)
      uri = URI("#{@base_url}#{path}")
      req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req.basic_auth(@user_id, @api_token)
      req.set_form_data(params) if params
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
      JSON.parse(response.body)
    end
  end
end
