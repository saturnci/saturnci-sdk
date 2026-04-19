# frozen_string_literal: true

require 'json'

module SaturnCI
  class Build
    TERMINAL_STATUSES = %w[Passed Failed Cancelled].freeze

    attr_reader :id, :url, :container_image_url

    def initialize(id:, client:, url: nil)
      @id = id
      @client = client
      @url = url
    end

    def self.create(client:, repository:, name:, **params)
      response = client.post('/api/v1/builds', { repository: repository, build_name: name }.merge(params))
      body = JSON.parse(response.body)
      new(id: body['id'], client: client, url: body['url'])
    end

    def wait_for_completion
      loop do
        response = JSON.parse(@client.get("/api/v1/builds/#{@id}").body)
        if TERMINAL_STATUSES.include?(response['status'])
          @container_image_url = response['container_image_url']
          return response
        end

        sleep 5
      end
    end
  end
end
