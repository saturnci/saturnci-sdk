# frozen_string_literal: true

module SaturnCI
  class Client
    def initialize(user_id: nil, api_token: nil)
      @user_id = user_id
      @api_token = api_token
    end

    def authenticated?
      return false unless @user_id.nil? || @api_token.nil?

      puts 'Credentials not found'
      false
    end
  end
end
