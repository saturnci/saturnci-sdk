# frozen_string_literal: true

module SaturnCI
  class Environment
    def initialize(job_run:)
      @job_run = job_run
    end
  end
end
