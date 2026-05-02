# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::GitHubOAuthGrant do
  describe '.destroy' do
    it 'sends a DELETE to the github oauth grant endpoint' do
      stub = stub_request(:delete, 'https://app.saturnci.com/api/v1/github_oauth_grant')
             .to_return(status: 204)

      client = SaturnCI::Client.new(TestHelpers.credentials)
      SaturnCI::GitHubOAuthGrant.destroy(client: client)

      expect(stub).to have_been_requested
    end
  end
end
