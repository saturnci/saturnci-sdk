# frozen_string_literal: true

class DefaultWorkflow
  def initialize(env: ENV)
    @env = env
  end

  def perform(io: $stdout)
    clone_repo_job_run = create_clone_repo_job_run(io)
    return unless clone_repo_job_run.status == 'Passed'

    test_suite_run = create_test_suite_run(io)
    finish(io, test_suite_run_status(test_suite_run.id))
  end

  def create_clone_repo_job_run(io)
    workflow_run.job_runs.create(
      job_name: 'clone_repo',
      task_adapter_name: 'shell',
      idempotent: true
    ).tap do |job_run|
      io.puts "Created clone_repo job run: id=#{job_run.id} url=#{job_run.url}"
      io.puts "Not starting a test_suite run: clone_repo status is #{job_run.status}" unless job_run.status == 'Passed'
    end
  end

  def create_test_suite_run(io)
    workflow_run.test_suite_runs.create(
      job_name: 'test_suite',
      task_adapter_name: 'rspec',
      task_adapter_version: '2',
      idempotent: true
    ).tap do |test_suite_run|
      io.puts "Started test_suite run: id=#{test_suite_run.id} url=#{test_suite_run.url}"
    end
  end

  def finish(io, test_suite_status)
    unless %w[Passed Failed].include?(test_suite_status)
      io.puts "Not finishing the workflow: test_suite status is #{test_suite_status}"
      return
    end

    workflow_run.finish
    io.puts 'Workflow finished.'
  end

  def test_suite_run_status(id, client: saturnci_client)
    SaturnCI::TestSuiteRun.find(client: client, id: id).status
  end

  def workflow_run(client: saturnci_client)
    @workflow_run ||= SaturnCI::WorkflowRun.find(
      client: client,
      id: @env.fetch('WORKFLOW_RUN_ID')
    )
  end

  def saturnci_client
    SaturnCI::Client.new(
      SaturnCI::Credentials.new(api_token: @env.fetch('SATURNCI_ACCESS_TOKEN'))
    )
  end
end

DefaultWorkflow.new.perform if $PROGRAM_NAME == __FILE__
