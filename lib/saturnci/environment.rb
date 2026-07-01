# frozen_string_literal: true

module SaturnCI
  class Environment
    def initialize(job_run:, client:, shell: Shell.new)
      @job_run = job_run
      @client = client
      @shell = shell
    end

    def github_token
      @client.post(
        '/api/v1/task_agents/github_tokens',
        github_installation_id: @job_run.repository.github_installation_id
      ).body
    end

    def file_exists?(path)
      File.exist?(path)
    end

    def copy(source, destination)
      @shell.execute("cp -a #{source}/. #{destination}/")
    end

    def clone_repo
      token_url = "https://x-access-token:#{github_token}@github.com/"
      pipeline_workspace_dir = @job_run.pipeline_workspace_dir
      @shell.execute(
        'git ' \
        "-c url.\"#{token_url}\".insteadOf=\"https://github.com/\" " \
        "-c url.\"#{token_url}\".insteadOf=\"git@github.com:\" " \
        "clone --recurse-submodules https://github.com/#{@job_run.repository.github_repo_full_name} " \
        "#{pipeline_workspace_dir}"
      )
      unless Dir.exist?(pipeline_workspace_dir) && !Dir.empty?(pipeline_workspace_dir)
        raise "pipeline workspace not readable after clone: #{pipeline_workspace_dir}"
      end

      pipeline_workspace_dir
    end
  end
end
