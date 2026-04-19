# frozen_string_literal: true

require 'json'

module SaturnCI
  class Build
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def self.create(client:, repository:, name:, **params)
      response = client.post('/api/v1/builds', { repository: repository, build_name: name }.merge(params))
      body = JSON.parse(response.body)
      new(id: body['id'])
    end
  end
end
