# frozen_string_literal: true

require 'spec_helper'

describe SaturnCI::WorkflowRun do
  describe '.find' do
    it 'fetches the workflow run' do
      client = SaturnCI::Client.new(double(api_token: 'x'))

      stub_request(:get, 'https://app.saturnci.com/api/v1/workflow_runs/abc123')
        .to_return(status: 200, body: '{"id": "abc123"}')

      workflow_run = SaturnCI::WorkflowRun.find(client: client, id: 'abc123')

      expect(workflow_run.id).to eq('abc123')
    end
  end
end
