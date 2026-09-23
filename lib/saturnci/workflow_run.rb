# frozen_string_literal: true

require 'json'

module SaturnCI
  class WorkflowRun
    attr_reader :id, :branch_name, :commit_hash, :commit_message, :author_name,
                :repository_full_name

    def initialize(id:, client:, branch_name: nil, commit_hash: nil, commit_message: nil,
                   author_name: nil, repository_full_name: nil)
      @id = id
      @client = client
      @branch_name = branch_name
      @commit_hash = commit_hash
      @commit_message = commit_message
      @author_name = author_name
      @repository_full_name = repository_full_name
    end

    def job_runs
      JobRuns.new(workflow_run: self, client: @client)
    end

    def test_suite_runs
      TestSuiteRuns.new(workflow_run: self, client: @client)
    end

    def self.find(client:, id:)
      body = JSON.parse(client.get("/api/v1/workflow_runs/#{id}").body)
      new(
        id: body['id'],
        client: client,
        branch_name: body['branch_name'],
        commit_hash: body['commit_hash'],
        commit_message: body['commit_message'],
        author_name: body['author_name'],
        repository_full_name: body['repository_full_name']
      )
    end
  end
end
