# frozen_string_literal: true

require 'json'

module SaturnCI
  class Build
    ACTIVE_STATUSES = ['Running', 'Queued', 'Not Started'].freeze

    attr_reader :id

    def initialize(id:, client:)
      @id = id
      @client = client
    end

    def self.create(client:, repository:, name:, **params)
      response = client.post('/api/v1/builds', { repository: repository, build_name: name }.merge(params))
      body = JSON.parse(response.body)
      new(id: body['id'], client: client)
    end

    def wait
      loop do
        response = JSON.parse(@client.get("/api/v1/builds/#{@id}").body)
        return response unless ACTIVE_STATUSES.include?(response['status'])

        sleep 5
      end
    end
  end
end
