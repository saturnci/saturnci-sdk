# frozen_string_literal: true

require 'spec_helper'
load File.expand_path('../../.saturnci/workflows/default_workflow.rb', __dir__)

describe '.saturnci/workflows/default_workflow.rb' do
  let!(:env) do
    {
      'SATURNCI_ACCESS_TOKEN' => 'token123',
      'WORKFLOW_RUN_ID' => 'workflow123'
    }
  end

  let!(:job_runs) { double('job_runs') }

  let!(:workflow_run) do
    double(
      'workflow_run',
      id: 'workflow123',
      repository_full_name: 'saturnci/saturnci-sdk',
      branch_name: 'main',
      commit_hash: 'abc123',
      job_runs: job_runs
    )
  end

  it 'creates a clone_repo job run' do
    job_run = double('job_run', id: 'job123', url: 'https://example.com/job123', status: 'Running',
                                start: nil)
    allow(job_runs).to receive(:create).and_return(job_run)

    default_workflow = DefaultWorkflow.new(env: env)
    allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)

    default_workflow.perform(io: StringIO.new)

    expect(job_runs).to have_received(:create).with(
      job_name: 'clone_repo',
      task_adapter_name: 'shell',
      idempotent: true
    )
  end

  it 'starts the clone_repo job run it created' do
    job_run = double('job_run', id: 'job123', url: 'https://example.com/job123',
                                status: 'Not Started', start: nil)
    allow(job_runs).to receive(:create).and_return(job_run)

    default_workflow = DefaultWorkflow.new(env: env)
    allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)

    default_workflow.perform(io: StringIO.new)

    expect(job_run).to have_received(:start)
  end

  context 'when the clone_repo job run has passed' do
    let!(:test_suite_runs) { double('test_suite_runs') }

    before do
      allow(job_runs).to receive(:create).and_return(
        double('job_run', id: 'job123', url: 'https://example.com/job123', status: 'Passed',
                          start: nil)
      )
      allow(workflow_run).to receive(:test_suite_runs).and_return(test_suite_runs)
      allow(test_suite_runs).to receive(:create).and_return(
        double('test_suite_run', id: 'tsr123', url: 'https://example.com/tsr123', start: nil)
      )
    end

    it 'starts a test_suite run' do
      default_workflow = DefaultWorkflow.new(env: env)
      allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
      allow(default_workflow).to receive(:test_suite_run_status).and_return('Running')

      default_workflow.perform(io: StringIO.new)

      expect(test_suite_runs).to have_received(:create).with(
        job_name: 'test_suite',
        task_adapter_name: 'rspec',
        task_adapter_version: '2',
        idempotent: true
      )
    end

    it 'starts the test_suite run it created' do
      test_suite_run = double('test_suite_run', id: 'tsr123', url: 'https://example.com/tsr123',
                                                start: nil)
      allow(test_suite_runs).to receive(:create).and_return(test_suite_run)

      default_workflow = DefaultWorkflow.new(env: env)
      allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
      allow(default_workflow).to receive(:test_suite_run_status).and_return('Running')

      default_workflow.perform(io: StringIO.new)

      expect(test_suite_run).to have_received(:start)
    end

    context 'and the test_suite run has passed' do
      it 'creates a workflow environment image build job run' do
        default_workflow = DefaultWorkflow.new(env: env)
        allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
        allow(default_workflow).to receive(:test_suite_run_status).and_return('Passed')
        allow(workflow_run).to receive(:finish)

        default_workflow.perform(io: StringIO.new)

        expect(job_runs).to have_received(:create).with(
          job_name: 'workflow_environment_image_build',
          task_adapter_name: 'shell',
          idempotent: true
        )
      end

      it 'finishes the workflow run' do
        allow(workflow_run).to receive(:finish)

        default_workflow = DefaultWorkflow.new(env: env)
        allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
        allow(default_workflow).to receive(:test_suite_run_status).and_return('Passed')

        default_workflow.perform(io: StringIO.new)

        expect(workflow_run).to have_received(:finish)
      end
    end

    context 'and the test_suite run is still running' do
      it 'creates no workflow environment image build job run' do
        allow(workflow_run).to receive(:finish)

        default_workflow = DefaultWorkflow.new(env: env)
        allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
        allow(default_workflow).to receive(:test_suite_run_status).and_return('Running')

        default_workflow.perform(io: StringIO.new)

        expect(job_runs).not_to have_received(:create).with(
          hash_including(job_name: 'workflow_environment_image_build')
        )
      end

      it 'leaves the workflow run unfinished' do
        allow(workflow_run).to receive(:finish)

        default_workflow = DefaultWorkflow.new(env: env)
        allow(default_workflow).to receive(:workflow_run).and_return(workflow_run)
        allow(default_workflow).to receive(:test_suite_run_status).and_return('Running')

        default_workflow.perform(io: StringIO.new)

        expect(workflow_run).not_to have_received(:finish)
      end
    end
  end
end
