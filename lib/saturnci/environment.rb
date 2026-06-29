# frozen_string_literal: true

module SaturnCI
  class Environment
    def initialize(job_run:, shell: Shell.new)
      @job_run = job_run
      @shell = shell
    end

    def clone_repo
      raise 'git clone failed' unless @shell.execute('git clone')
    end
  end
end
