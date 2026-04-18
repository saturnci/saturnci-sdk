# frozen_string_literal: true

module SaturnCI
  class Configuration
    attr_accessor :user_id, :api_token, :base_url

    def initialize
      @base_url = 'https://app.saturnci.com'
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
