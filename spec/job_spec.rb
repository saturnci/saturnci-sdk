# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Job do
  describe '.create' do
    it 'posts to the jobs endpoint and returns a job with an id' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/jobs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      job = SaturnCI::Job.create(client: client, repository: 'saturnci/saturnci', name: 'deploy')

      expect(job.id).to eq('abc123')
    end

    it 'passes additional params to the API' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/jobs')
        .with(body: { repository: 'saturnci/saturnci', job_name: 'deploy',
                      container_image_url: 'some-image:latest' })
        .to_return(status: 201, body: '{"id": "abc123"}')

      job = SaturnCI::Job.create(client: client, repository: 'saturnci/saturnci', name: 'deploy',
                                 container_image_url: 'some-image:latest')

      expect(job.id).to eq('abc123')
    end
  end

  describe '#wait_for_completion' do
    it 'polls until the job is finished and returns the response' do
      running_response = double(body: '{"status": "Running"}')
      finished_response = double(body: '{"status": "Passed"}')
      client = double
      allow(client).to receive(:get).and_return(running_response, finished_response)

      job = SaturnCI::Job.new(id: 'abc123', client: client)
      allow(job).to receive(:sleep)

      expect(job.status).to be_nil

      job.wait_for_completion

      expect(job.status).to eq('Passed')
    end
  end
end
