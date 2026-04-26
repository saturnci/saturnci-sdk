# frozen_string_literal: true

module TestHelpers
  def self.credentials
    SaturnCI::Credentials.new(api_token: 'x')
  end
end
