# frozen_string_literal: true

require 'net/http'
require 'uri'

module SaturnCI
  class Client
    AUTHENTICATION_CHECK_PATH = '/api/v1/test_suite_runs'

    def initialize(user_id: nil, api_token: nil, base_url: 'https://app.saturnci.com')
      @user_id = user_id
      @api_token = api_token
      @base_url = base_url
    end

    def authenticated?
      if @user_id.nil? || @api_token.nil?
        puts 'Credentials not found'
        return false
      end

      uri = URI("#{@base_url}#{AUTHENTICATION_CHECK_PATH}")
      req = Net::HTTP::Get.new(uri)
      req.basic_auth(@user_id, @api_token)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
      response.is_a?(Net::HTTPSuccess)
    end
  end
end
