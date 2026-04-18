# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Job do
  describe '.create' do
    it 'posts to the jobs endpoint and returns a job with an id' do
      SaturnCI.configure do |config|
        config.user_id = 'test_user'
        config.api_token = 'test_token'
      end

      stub_request(:post, 'https://app.saturnci.com/api/v1/jobs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      job = SaturnCI::Job.create(repository: 'saturnci/saturnci', name: 'deploy')

      expect(job.id).to eq('abc123')
    end
  end
end
