# frozen_string_literal: true

require 'json'
require 'uri'

module SaturnCI
  class TestSuiteRun
    TERMINAL_STATUSES = ['Passed', 'Failed', 'Cancelled', 'Timed Out'].freeze

    attr_reader :id, :url, :status

    def initialize(id:, client:, url: nil)
      @id = id
      @client = client
      @url = url
    end

    def self.list(client:, commit_hash:)
      query = URI.encode_www_form(commit_hash: commit_hash)
      response = client.get("/api/v1/test_suite_runs?#{query}")
      JSON.parse(response.body).map { |test_suite_run| new(id: test_suite_run['id'], client: client) }
    end

    def self.create(client:, repository:, branch_name:, commit_hash:, commit_message:, author_name:)
      response = client.post('/api/v1/test_suite_runs', {
                               repository: repository,
                               branch_name: branch_name,
                               commit_hash: commit_hash,
                               commit_message: commit_message,
                               author_name: author_name
                             })
      body = JSON.parse(response.body)
      new(id: body['id'], client: client, url: body['url'])
    end

    def wait_for_completion
      loop do
        response = JSON.parse(@client.get("/api/v1/test_suite_runs/#{@id}").body)
        if TERMINAL_STATUSES.include?(response['status'])
          @status = response['status']
          return response
        end

        sleep 5
      end
    end
  end
end
