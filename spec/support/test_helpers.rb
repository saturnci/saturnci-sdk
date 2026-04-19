# frozen_string_literal: true

module TestHelpers
  def self.credentials
    SaturnCI::Credentials.new(user_id: 'x', api_token: 'x')
  end
end
