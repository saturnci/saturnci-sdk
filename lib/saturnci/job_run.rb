# frozen_string_literal: true

require 'json'
require 'uri'

module SaturnCI
  class JobRun
    TERMINAL_STATUSES = ['Passed', 'Failed', 'Cancelled', 'Timed Out'].freeze

    attr_reader :id, :url, :status, :parent_job_run_id, :job_name, :branch_name, :params, :repository

    def initialize(id:, client:, url: nil, parent_job_run_id: nil, job_name: nil, status: nil, branch_name: nil,
                   params: nil, repository: nil)
      @id = id
      @client = client
      @url = url
      @parent_job_run_id = parent_job_run_id
      @job_name = job_name
      @status = status
      @branch_name = branch_name
      @params = params
      @repository = repository
    end

    def self.find(client:, id:)
      body = JSON.parse(client.get("/api/v1/job_runs/#{id}").body)
      new(
        id: body['id'],
        client: client,
        job_name: body['job_name'],
        status: body['status'],
        branch_name: body['branch_name'],
        parent_job_run_id: body['parent_job_run_id'],
        params: body['params'],
        repository: repository_from(body['repository'])
      )
    end

    def self.repository_from(attributes)
      return unless attributes

      Repository.new(
        github_repo_full_name: attributes['github_repo_full_name'],
        github_installation_id: attributes['github_installation_id']
      )
    end

    def update(**params)
      @client.patch("/api/v1/job_runs/#{@id}", params)
    end

    def environment
      Environment.new(job_run: self, client: @client)
    end

    def self.list(client:, job_name:, status: nil)
      params = { job_name: job_name }
      params[:status] = status if status
      query = URI.encode_www_form(params)
      response = client.get("/api/v1/job_runs?#{query}")
      JSON.parse(response.body).map { |job_run| new(id: job_run['id'], client: client) }
    end

    def self.create(client:, repository:, job_name:, **params)
      response = client.post('/api/v1/job_runs', { repository: repository, job_name: job_name }.merge(params))
      body = JSON.parse(response.body)
      new(id: body['id'], client: client, url: body['url'], parent_job_run_id: body['parent_job_run_id'])
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
