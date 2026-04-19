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
end
