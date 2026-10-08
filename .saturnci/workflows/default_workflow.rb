# frozen_string_literal: true

class DefaultWorkflow
  def initialize(env: ENV)
    @env = env
  end

  def perform(io: $stdout)
    test_suite_run = current_test_suite_run(create_test_suite_run(io).id)

    create_workflow_environment_image_build_job_run(io) if test_suite_run.passed?

    finish(io, test_suite_run)
  end

  def create_workflow_environment_image_build_job_run(io)
    workflow_run.job_runs.create(
      job_name: 'workflow_environment_image_build',
      task_adapter_name: 'shell',
      idempotent: true
    ).tap do |job_run|
      job_run.start
      io.puts "Started workflow_environment_image_build job run: id=#{job_run.id} url=#{job_run.url}"
    end
  end

  def create_test_suite_run(io)
    workflow_run.test_suite_runs.create(
      job_name: 'test_suite',
      task_adapter_name: 'rspec',
      task_adapter_version: '2',
      idempotent: true
    ).tap do |test_suite_run|
      test_suite_run.start
      io.puts "Started test_suite run: id=#{test_suite_run.id} url=#{test_suite_run.url}"
    end
  end

  def finish(io, test_suite_run)
    unless test_suite_run.passed? || test_suite_run.failed?
      io.puts "Not finishing the workflow: test_suite status is #{test_suite_run.status}"
      return
    end

    workflow_run.finish
    io.puts 'Workflow finished.'
  end

  def current_test_suite_run(id, client: saturnci_client)
    SaturnCI::TestSuiteRun.find(client: client, id: id)
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
