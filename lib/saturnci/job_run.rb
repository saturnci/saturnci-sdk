# frozen_string_literal: true

require 'json'

module SaturnCI
  class JobRun
    TERMINAL_STATUSES = %w[Passed Failed Cancelled].freeze

    attr_reader :id, :url, :status

    def initialize(id:, client:, url: nil)
      @id = id
      @client = client
      @url = url
    end

    def self.create(client:, repository:, name:, **params)
      response = client.post('/api/v1/job_runs', { repository: repository, job_name: name }.merge(params))
      body = JSON.parse(response.body)
      new(id: body['id'], client: client, url: body['url'])
    end

    def wait_for_completion
      loop do
        response = JSON.parse(@client.get("/api/v1/job_runs/#{@id}").body)
        if TERMINAL_STATUSES.include?(response['status'])
          @status = response['status']
          return response
        end

        sleep 5
      end
    end
  end
end
