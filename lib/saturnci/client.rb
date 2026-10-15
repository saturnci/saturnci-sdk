# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module SaturnCI
  class Client
    AUTHENTICATION_CHECK_PATH = '/api/v1/test_suite_runs'

    def initialize(credentials = Credentials.new, base_url: ENV.fetch('SATURNCI_API_HOST', 'https://app.saturnci.com'))
      @api_token = credentials.api_token
      @base_url = base_url
    end

    def authenticated?
      return false if @api_token.nil?

      get(AUTHENTICATION_CHECK_PATH)
      true
    rescue InvalidRequestError
      false
    end

    def get(path)
      request(Net::HTTP::Get.new(uri(path)))
    end

    def post(path, params = {})
      request(Net::HTTP::Post.new(uri(path)), params)
    end

    def patch(path, params = {})
      request(Net::HTTP::Patch.new(uri(path)), params)
    end

    def delete(path)
      request(Net::HTTP::Delete.new(uri(path)))
    end

    private

    def uri(path)
      URI("#{@base_url}#{path}")
    end

    def request(http_request, params = nil)
      http_request['Authorization'] = "Bearer #{@api_token}"
      if params
        http_request['Content-Type'] = 'application/json'
        http_request.body = params.to_json
      end

      request_uri = http_request.uri
      response = Net::HTTP.start(
        request_uri.hostname, request_uri.port, use_ssl: request_uri.scheme == 'https'
      ) do |http|
        http.request(http_request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise InvalidRequestError, "API returned #{response.code}: #{response.body}"
      end

      response
    end
  end
end
