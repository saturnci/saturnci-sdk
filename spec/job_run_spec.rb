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
