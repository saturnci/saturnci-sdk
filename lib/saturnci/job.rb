# frozen_string_literal: true

require 'json'

module SaturnCI
  class Job
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def self.create(repository:, name:)
      config = SaturnCI.configuration
      client = Client.new(user_id: config.user_id, api_token: config.api_token, base_url: config.base_url)
      response = client.post('/api/v1/jobs', repository: repository, job_name: name)
      body = JSON.parse(response.body)
      new(id: body['id'])
    end
  end
end
