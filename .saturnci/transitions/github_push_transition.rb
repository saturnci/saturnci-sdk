# frozen_string_literal: true

class GitHubPushTransition
  def after(_job_run)
    [
      {
        task_adapter_name: 'rspec',
        task_adapter_version: '2',
        job_name: 'test_suite',
        job_run_type: 'test_suite_run'
      }
    ]
  end
end
