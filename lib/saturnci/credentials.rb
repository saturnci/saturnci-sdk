# frozen_string_literal: true

require 'json'

module SaturnCI
  class Credentials
    CREDENTIALS_PATH = '~/.saturnci/credentials.json'

    attr_reader :api_token

    def initialize(api_token: nil)
      if api_token
        @api_token = api_token
      else
        file = JSON.parse(File.read(File.expand_path(CREDENTIALS_PATH)))
        @api_token = file['api_token']
      end
    end
  end
end
