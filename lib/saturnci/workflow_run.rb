# frozen_string_literal: true

require 'json'

module SaturnCI
  class WorkflowRun
    attr_reader :id

    def initialize(id:, client:)
      @id = id
      @client = client
    end

    def self.find(client:, id:)
      body = JSON.parse(client.get("/api/v1/workflow_runs/#{id}").body)
      new(id: body['id'], client: client)
    end
  end
end
