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

    def clone_repo
      @shell.execute('git clone --recurse-submodules')
    end
  end
end
