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
      request(Net::HTTP::Get, path)
    end

    def post(path, params = {})
      request(Net::HTTP::Post, path, params)
    end

    def patch(path, params = {})
      request(Net::HTTP::Patch, path, params)
    end

    def delete(path)
      request(Net::HTTP::Delete, path)
    end

    private

    def request(method_class, path, params = nil)
      uri = URI("#{@base_url}#{path}")
      req = method_class.new(uri)
      req['Authorization'] = "Bearer #{@api_token}"
      if params
        req['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
      unless response.is_a?(Net::HTTPSuccess)
        raise InvalidRequestError, "API returned #{response.code}: #{response.body}"
      end

      response
    end
  end
end
