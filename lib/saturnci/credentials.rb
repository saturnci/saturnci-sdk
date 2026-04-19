# frozen_string_literal: true

require 'json'

module SaturnCI
  class Credentials
    CREDENTIALS_PATH = '~/.saturnci/credentials.json'

    attr_reader :user_id, :api_token

    def initialize(user_id: nil, api_token: nil)
      if user_id && api_token
        @user_id = user_id
        @api_token = api_token
      else
        file = JSON.parse(File.read(File.expand_path(CREDENTIALS_PATH)))
        @user_id = file['user_id']
        @api_token = file['api_token']
      end
    end
  end
end
