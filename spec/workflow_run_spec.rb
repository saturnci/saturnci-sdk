# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::WorkflowRun do
  describe '.find' do
    it 'fetches the workflow run' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/workflow_runs/abc123')
        .to_return(status: 200, body: '{"id": "abc123"}')

      workflow_run = SaturnCI::WorkflowRun.find(client: client, id: 'abc123')

      expect(workflow_run.id).to eq('abc123')
    end
  end

  describe '#job_runs' do
    describe '#create' do
      it "posts a job run with the workflow run's repository, git metadata, and id" do
        client = SaturnCI::Client.new(double(api_token: 'x'))
        workflow_run = SaturnCI::WorkflowRun.new(
          id: 'workflow123',
          client: client,
          branch_name: 'main',
          commit_hash: 'abc123',
          commit_message: 'commit message',
          author_name: 'author name',
          repository_full_name: 'saturnci/saturnci'
        )

        create_request = stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
                         .with(body: { repository: 'saturnci/saturnci', job_name: 'clone_repo',
                                       branch_name: 'main', commit_hash: 'abc123',
                                       commit_message: 'commit message', author_name: 'author name',
                                       workflow_run_id: 'workflow123' })
                         .to_return(status: 201, body: '{"id": "jobrun123"}')

        workflow_run.job_runs.create(job_name: 'clone_repo')

        expect(create_request).to have_been_requested
      end

      it 'returns the created job run' do
        client = SaturnCI::Client.new(double(api_token: 'x'))
        workflow_run = SaturnCI::WorkflowRun.new(
          id: 'workflow123',
          client: client,
          repository_full_name: 'saturnci/saturnci'
        )

        stub_request(:post, 'https://app.saturnci.com/api/v1/job_runs')
          .to_return(status: 201, body: '{"id": "jobrun123"}')

        job_run = workflow_run.job_runs.create(job_name: 'clone_repo')

        expect(job_run.id).to eq('jobrun123')
      end
    end
  end

  describe '#finish' do
    it 'records that the workflow run finished' do
      client = SaturnCI::Client.new(double(api_token: 'x'))
      workflow_run = SaturnCI::WorkflowRun.new(id: 'workflow123', client: client)

      finish_request = stub_request(:post, 'https://app.saturnci.com/api/v1/workflow_runs/workflow123/finished_events')
                       .to_return(status: 201)

      workflow_run.finish

      expect(finish_request).to have_been_requested
    end
  end

  describe '#test_suite_runs' do
    describe '#create' do
      it "posts a test suite run with the workflow run's repository, git metadata, and id" do
        client = SaturnCI::Client.new(double(api_token: 'x'))
        workflow_run = SaturnCI::WorkflowRun.new(
          id: 'workflow123',
          client: client,
          branch_name: 'main',
          commit_hash: 'abc123',
          commit_message: 'commit message',
          author_name: 'author name',
          repository_full_name: 'saturnci/saturnci'
        )

        create_request = stub_request(:post, 'https://app.saturnci.com/api/v1/test_suite_runs')
                         .with(body: { repository: 'saturnci/saturnci', job_name: 'test_suite',
                                       branch_name: 'main', commit_hash: 'abc123',
                                       commit_message: 'commit message', author_name: 'author name',
                                       workflow_run_id: 'workflow123' })
                         .to_return(status: 201, body: '{"id": "tsr123"}')

        workflow_run.test_suite_runs.create(job_name: 'test_suite')

        expect(create_request).to have_been_requested
      end
    end
  end
end
