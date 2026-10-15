# frozen_string_literal: true

require 'net/http'

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
      APIRequest.new(Net::HTTP::Get, @api_token, @base_url, path).response
    end

    def post(path, params = {})
      APIRequest.new(Net::HTTP::Post, @api_token, @base_url, path, params).response
    end

    def patch(path, params = {})
      APIRequest.new(Net::HTTP::Patch, @api_token, @base_url, path, params).response
    end

    def delete(path)
      APIRequest.new(Net::HTTP::Delete, @api_token, @base_url, path).response
    end
  end
end
