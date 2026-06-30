# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::JobRun do
  describe '.find' do
    it 'fetches the job run and exposes its job name, status, and branch name' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs/abc123')
        .to_return(status: 200,
                   body: '{"id": "abc123", "job_name": "github_push", "status": "Passed", "branch_name": "main"}')

      job_run = SaturnCI::JobRun.find(client: client, id: 'abc123')

      expect(job_run.job_name).to eq('github_push')
      expect(job_run.status).to eq('Passed')
      expect(job_run.branch_name).to eq('main')
    end

    it 'exposes the repository github metadata' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs/abc123')
        .to_return(status: 200,
                   body: '{"id": "abc123", "repository": ' \
                         '{"github_repo_full_name": "saturnci/saturnci", "github_installation_id": "12345678"}}')

      job_run = SaturnCI::JobRun.find(client: client, id: 'abc123')

      expect(job_run.repository.github_repo_full_name).to eq('saturnci/saturnci')
      expect(job_run.repository.github_installation_id).to eq('12345678')
    end

    it 'exposes the params' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs/abc123')
        .to_return(status: 200,
                   body: '{"id": "abc123", "params": {"container_image_url": "registry/app:abc"}}')

      job_run = SaturnCI::JobRun.find(client: client, id: 'abc123')

      expect(job_run.params).to eq('container_image_url' => 'registry/app:abc')
    end
  end

  describe '#update' do
    it 'patches the job run with the given params' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:patch, 'https://app.saturnci.com/api/v1/job_runs/abc123')
        .with(body: { 'container_image_url' => 'registry/app:abc' })
        .to_return(status: 200, body: '{"id": "abc123"}')

      job_run = SaturnCI::JobRun.new(id: 'abc123', client: client)

      job_run.update(container_image_url: 'registry/app:abc')

      expect(WebMock).to have_requested(:patch, 'https://app.saturnci.com/api/v1/job_runs/abc123')
        .with(body: { 'container_image_url' => 'registry/app:abc' })
    end
  end

  describe '.create' do
    it 'posts to the job_runs endpoint and returns a job run with an id' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy')

      expect(job_run.id).to eq('abc123')
    end

    it 'passes additional params to the API' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .with(body: { repository: 'saturnci/saturnci', job_name: 'deploy',
                      container_image_url: 'some-image:latest' })
        .to_return(status: 201, body: '{"id": "abc123"}')

      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy',
                                        container_image_url: 'some-image:latest')

      expect(job_run.id).to eq('abc123')
    end

    it 'exposes the parent job run id from the response' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
        .to_return(status: 201, body: '{"id": "abc123", "parent_job_run_id": "parent123"}')

      job_run = SaturnCI::JobRun.create(client: client, repository: 'saturnci/saturnci', job_name: 'deploy')

      expect(job_run.parent_job_run_id).to eq('parent123')
    end
  end

  describe '.list' do
    it 'returns job runs matching the given job_name' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

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
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy')
        .to_return(status: 200, body: '[{"id": "deploy-id"}]')
      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=lint')
        .to_return(status: 200, body: '[{"id": "lint-id"}]')

      job_runs = SaturnCI::JobRun.list(client: client, job_name: 'deploy')

      expect(job_runs.map(&:id)).to contain_exactly('deploy-id')
    end

    it 'passes status through to the API' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy&status=Running')
        .to_return(status: 200, body: '[{"id": "running-id"}]')

      job_runs = SaturnCI::JobRun.list(client: client, job_name: 'deploy', status: 'Running')

      expect(job_runs.map(&:id)).to contain_exactly('running-id')
    end

    it 'does not return job runs with a non-matching status' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy&status=Running')
        .to_return(status: 200, body: '[{"id": "running-id"}]')
      stub_request(:get, 'https://app.saturnci.com/api/v1/job_runs?job_name=deploy&status=Passed')
        .to_return(status: 200, body: '[{"id": "passed-id"}]')

      job_runs = SaturnCI::JobRun.list(client: client, job_name: 'deploy', status: 'Running')

      expect(job_runs.map(&:id)).to contain_exactly('running-id')
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

    it 'treats a timed-out job run as finished' do
      running_response = double(body: '{"status": "Running"}')
      timed_out_response = double(body: '{"status": "Timed Out"}')
      client = double
      allow(client).to receive(:get).and_return(running_response, timed_out_response)

      job_run = SaturnCI::JobRun.new(id: 'abc123', client: client)
      allow(job_run).to receive(:sleep)

      job_run.wait_for_completion

      expect(job_run.status).to eq('Timed Out')
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

  describe '#environment' do
    it 'is an environment' do
      job_run = SaturnCI::JobRun.new(id: 'abc123', client: double)

      expect(job_run.environment).to be_a(SaturnCI::Environment)
    end
  end
end
