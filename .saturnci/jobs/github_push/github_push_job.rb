# frozen_string_literal: true

class GitHubPushJob
  def initialize(io: $stdout)
    @io = io
  end

  def perform(job_run)
    if job_run.environment.file_exists?(job_run.pipeline_workspace_dir)
      @io.puts "Working copy of #{job_run.repository.github_repo_full_name} " \
               "found at #{job_run.pipeline_workspace_dir}"
    else
      @io.puts "Working copy of #{job_run.repository.github_repo_full_name} not found in pipeline workspace, " \
               "cloning into #{job_run.pipeline_workspace_dir}"
      job_run.environment.clone_repo
    end
  end
end

if $PROGRAM_NAME == __FILE__
  client = SaturnCI::Client.new(SaturnCI::Credentials.new(api_token: ENV.fetch('SATURNCI_ACCESS_TOKEN')))
  job_run = SaturnCI::JobRun.find(client: client, id: ENV.fetch('JOB_RUN_ID'))
  GitHubPushJob.new.perform(job_run)
end
