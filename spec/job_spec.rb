# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Job do
  describe '.create' do
    it 'posts to the jobs endpoint and returns a job with an id' do
      client = SaturnCI::Client.new(user_id: 'test_user', api_token: 'test_token')

      stub_request(:post, 'https://app.saturnci.com/api/v1/jobs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      job = SaturnCI::Job.create(client: client, repository: 'saturnci/saturnci', name: 'deploy')

      expect(job.id).to eq('abc123')
    end

    it 'passes additional params to the API' do
      client = SaturnCI::Client.new(user_id: 'test_user', api_token: 'test_token')

      stub_request(:post, 'https://app.saturnci.com/api/v1/jobs')
        .with(body: { repository: 'saturnci/saturnci', job_name: 'deploy',
                      container_image_url: 'some-image:latest' })
        .to_return(status: 201, body: '{"id": "abc123"}')

      job = SaturnCI::Job.create(client: client, repository: 'saturnci/saturnci', name: 'deploy',
                                 container_image_url: 'some-image:latest')

      expect(job.id).to eq('abc123')
    end
  end
end
