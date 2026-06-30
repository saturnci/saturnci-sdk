# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::Environment do
  describe '#github_token' do
    it 'posts the installation id and returns the token' do
      client = SaturnCI::Client.new(double(api_token: 'x'))
      repository = SaturnCI::Repository.new(github_repo_full_name: 'saturnci/saturnci',
                                            github_installation_id: '12345678')
      job_run = double('job_run', repository: repository)
      environment = SaturnCI::Environment.new(job_run: job_run, client: client)

      stub_request(:post, 'https://app.saturnci.com/api/v1/task_agents/github_tokens')
        .with(body: { 'github_installation_id' => '12345678' })
        .to_return(status: 200, body: 'ghs_sometoken')

      expect(environment.github_token).to eq('ghs_sometoken')
    end
  end
end
