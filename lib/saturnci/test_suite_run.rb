# frozen_string_literal: true

require 'json'
require 'uri'
require_relative 'child_job_runs'

module SaturnCI
  class TestSuiteRun
    TERMINAL_STATUSES = ['Passed', 'Failed', 'Cancelled', 'Timed Out'].freeze

    attr_reader :id, :url, :status, :parent_job_run_id

    def initialize(id:, client:, url: nil, parent_job_run_id: nil)
      @id = id
      @client = client
      @url = url
      @parent_job_run_id = parent_job_run_id
    end

    def child_job_runs
      ChildJobRuns.new(parent_id: @id, client: @client)
    end

    def self.list(client:, commit_hash:)
      query = URI.encode_www_form(commit_hash: commit_hash)
      response = client.get("/api/v1/test_suite_runs?#{query}")
      JSON.parse(response.body).map { |test_suite_run| new(id: test_suite_run['id'], client: client) }
    end

    def self.create(client:, repository:, **params)
      body = JSON.parse(
        client.post('/api/v1/test_suite_runs', { repository: repository }.merge(params.compact)).body
      )
      new(id: body['id'], client: client, url: body['url'], parent_job_run_id: body['parent_job_run_id'])
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
