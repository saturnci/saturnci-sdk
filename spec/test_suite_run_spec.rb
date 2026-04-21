# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::TestSuiteRun do
  describe '.create' do
    it 'posts to the test suite runs endpoint and returns a test suite run with an id' do
      stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
        .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      test_suite_run = SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/book_tracker',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason'
      )

      expect(test_suite_run.id).to eq('abc123')
    end
  end

  describe '.where' do
    it 'returns test suite runs matching the given commit hash' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      body = '[{"id": "6a40fec7-b72c-45e0-87b5-4b5eb8a4567d"},' \
             '{"id": "7882258e-5cb8-413a-ac07-e9eb350786d4"}]'
      stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs?commit_hash=abc1234')
        .to_return(status: 200, body: body)

      test_suite_runs = SaturnCI::TestSuiteRun.where(client: client, commit_hash: 'abc1234')

      expect(test_suite_runs.map(&:id)).to eq(%w[
                                                6a40fec7-b72c-45e0-87b5-4b5eb8a4567d
                                                7882258e-5cb8-413a-ac07-e9eb350786d4
                                              ])
    end
  end
end
