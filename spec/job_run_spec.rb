# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::JobRun do
  describe '.create' do
    it 'posts to the job_runs endpoint and returns a job run with an id' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy')

      expect(job_run.id).to eq('abc123')
    end

    it 'passes additional params to the API' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .with(body: { repository: 'saturnci/saturnci', job_name: 'deploy',
                      container_image_url: 'some-image:latest' })
        .to_return(status: 201, body: '{"id": "abc123"}')

      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy',
                                        container_image_url: 'some-image:latest')

      expect(job_run.id).to eq('abc123')
    end
  end

  describe '.list' do
    it 'returns job runs matching the given job_name' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      body = '[{"id": "6a40fec7-b72c-45e0-87b5-4b5eb8a4567d"},' \
             '{"id": "7882258e-5cb8-413a-ac07-e9eb350786d4"}]'
      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy')
        .to_return(status: 200, body: body)

      job_runs = SaturnCI::JobRun.list(client: client, job_name: 'deploy')

      expect(job_runs.map(&:id)).to eq(%w[
                                         6a40fec7-b72c-45e0-87b5-4b5eb8a4567d
                                         7882258e-5cb8-413a-ac07-e9eb350786d4
                                       ])
    end

    it 'does not return job runs with a non-matching job_name' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy')
        .to_return(status: 200, body: '[{"id": "deploy-id"}]')
      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=lint')
        .to_return(status: 200, body: '[{"id": "lint-id"}]')

      job_runs = SaturnCI::JobRun.list(client: client, job_name: 'deploy')

      expect(job_runs.map(&:id)).to contain_exactly('deploy-id')
    end
  end

  describe '#wait_for_completion' do
    it 'polls until the job run is finished and returns the response' do
      running_response = double(body: '{"status": "Running"}')
      finished_response = double(body: '{"status": "Passed"}')
      client = double
      allow(client).to receive(:get).and_return(running_response, finished_response)

      job_run = SaturnCI::JobRun.new(id: 'abc123', client: client)
      allow(job_run).to receive(:sleep)

      expect(job_run.status).to be_nil

      job_run.wait_for_completion

      expect(job_run.status).to eq('Passed')
    end
  end

  describe '#url' do
    it 'populates url from the API response' do
      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .to_return(status: 201, body: '{"id": "abc123", "url": "https://app.saturnci.com/jobs/abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy')

      expect(job_run.url).to eq('https://app.saturnci.com/jobs/abc123')
    end
  end
end
