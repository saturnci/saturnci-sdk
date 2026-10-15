# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module SaturnCI
  class APIRequest
    def initialize(request_class, api_token, base_url, path, params = nil)
      @request_class = request_class
      @api_token = api_token
      @base_url = base_url
      @path = path
      @params = params
    end

    def response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(net_http_request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise InvalidRequestError, "API returned #{response.code}: #{response.body}"
      end

      response
    end

    private

    def uri
      URI("#{@base_url}#{@path}")
    end

    def net_http_request
      net_http_request = @request_class.new(uri)
      net_http_request['Authorization'] = "Bearer #{@api_token}"

      if @params
        net_http_request['Content-Type'] = 'application/json'
        net_http_request.body = @params.to_json
      end

      net_http_request
    end
  end
end
