# frozen_string_literal: true

module SaturnCI
  # The job runs invoked by a given run. Creating one here automatically sets
  # the parent to the run this collection belongs to, so the caller never has
  # to pass a parent_job_run_id.
  class ChildJobRuns
    def initialize(parent_id:, client:)
      @parent_id = parent_id
      @client = client
    end

    def create(**params)
      JobRun.create(client: @client, parent_job_run_id: @parent_id, **params)
    end
  end
end
