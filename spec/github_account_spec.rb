# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::GitHubAccount do
  describe '.list' do
    context 'when the API returns one github account' do
      it 'returns one element with that id' do
        stub_request(:get, 'https://app.saturnci.com/api/v1/github_accounts')
          .to_return(status: 200, body: '[{"id":"abc123"}]')

        client = SaturnCI::Client.new(TestHelpers.credentials)
        github_accounts = SaturnCI::GitHubAccount.list(client: client)

        expect(github_accounts.map(&:id)).to eq(['abc123'])
      end
    end
  end
end
