# frozen_string_literal: true

require 'json'

module SaturnCI
  class Job
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def self.create(client:, repository:, name:)
      response = client.post('/api/v1/jobs', repository: repository, job_name: name)
      body = JSON.parse(response.body)
      new(id: body['id'])
    end
  end
end
