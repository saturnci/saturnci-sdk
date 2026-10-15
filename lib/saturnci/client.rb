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
      APIRequest.new(Net::HTTP::Get, uri(path), @api_token).response
    end

    def post(path, params = {})
      APIRequest.new(Net::HTTP::Post, uri(path), @api_token, params).response
    end

    def patch(path, params = {})
      APIRequest.new(Net::HTTP::Patch, uri(path), @api_token, params).response
    end

    def delete(path)
      APIRequest.new(Net::HTTP::Delete, uri(path), @api_token).response
    end

    private

    def uri(path)
      URI("#{@base_url}#{path}")
    end
  end
end
