# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::TestSuiteRun do
  describe '#child_job_runs' do
    it 'creates a job run with this run as the parent' do
      client = SaturnCI::Client.new(TestHelpers.credentials)
      test_suite_run = SaturnCI::TestSuiteRun.new(id: 'parent-id', client: client)

      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
             .with(body: hash_including('parent_job_run_id' => 'parent-id', 'job_name' => 'deploy'))
             .to_return(status: 201, body: '{"id": "child-id"}')

      child = test_suite_run.child_job_runs.create(repository: 'saturnci/saturnci', job_name: 'deploy')

      expect(child).to be_a(SaturnCI::JobRun)
      expect(child.id).to eq('child-id')
      expect(stub).to have_been_requested
    end
  end

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

    it 'forwards task_adapter_name to the API when given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with(body: hash_including('task_adapter_name' => 'rspec'))
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/words',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason',
        task_adapter_name: 'rspec'
      )

      expect(stub).to have_been_requested
    end

    it 'forwards command to the API when given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with(body: hash_including('command' => 'bundle exec appraisal rails-7.1 rspec'))
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/words',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason',
        command: 'bundle exec appraisal rails-7.1 rspec'
      )

      expect(stub).to have_been_requested
    end

    it 'forwards parent_job_run_id to the API when given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with(body: hash_including('parent_job_run_id' => 'parent123'))
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/words',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason',
        parent_job_run_id: 'parent123'
      )

      expect(stub).to have_been_requested
    end

    it 'omits command from the request body when not given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with { |request| !request.body.include?('command') }
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/book_tracker',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason'
      )

      expect(stub).to have_been_requested
    end

    it 'omits task_adapter_name from the request body when not given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with { |request| !request.body.include?('task_adapter_name') }
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/book_tracker',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason'
      )

      expect(stub).to have_been_requested
    end

    it 'omits parent_job_run_id from the request body when not given' do
      stub = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
             .with { |request| !request.body.include?('parent_job_run_id') }
             .to_return(status: 201, body: '{"id": "abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::TestSuiteRun.create(
        client: client,
        repository: 'saturnci/book_tracker',
        branch_name: 'main',
        commit_hash: 'abc123',
        commit_message: 'Add feature',
        author_name: 'Jason'
      )

      expect(stub).to have_been_requested
    end
  end

  describe '.list' do
    it 'returns test suite runs matching the given commit hash' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      body = '[{"id": "6a40fec7-b72c-45e0-87b5-4b5eb8a4567d"},' \
             '{"id": "7882258e-5cb8-413a-ac07-e9eb350786d4"}]'
      stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs?commit_hash=abc1234')
        .to_return(status: 200, body: body)

      test_suite_runs = SaturnCI::TestSuiteRun.list(client: client, commit_hash: 'abc1234')

      expect(test_suite_runs.map(&:id)).to eq(%w[
                                                6a40fec7-b72c-45e0-87b5-4b5eb8a4567d
                                                7882258e-5cb8-413a-ac07-e9eb350786d4
                                              ])
    end
  end
end
