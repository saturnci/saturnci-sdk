# frozen_string_literal: true

module SaturnCI
  class WorkflowRun
    class JobRuns
      def initialize(workflow_run:, client:)
        @workflow_run = workflow_run
        @client = client
      end

      def create(job_name:, **params)
        JobRun.create(
          client: @client,
          repository: @workflow_run.repository_full_name,
          job_name: job_name,
          branch_name: @workflow_run.branch_name,
          commit_hash: @workflow_run.commit_hash,
          commit_message: @workflow_run.commit_message,
          author_name: @workflow_run.author_name,
          workflow_run_id: @workflow_run.id,
          **params
        )
      end
    end
  end
end
