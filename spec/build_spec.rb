# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Build do
  describe '.create' do
    it 'posts to the builds endpoint and returns a build with an id' do
      client = SaturnCI::Client.new(double(user_id: 'x', api_token: 'x'))

      stub_request(:post, 'https://app.saturnci.com/api/v1/builds')
        .to_return(status: 201, body: '{"id": "abc123"}')

      build = SaturnCI::Build.create(client: client, repository: 'saturnci/saturnci', name: 'production')

      expect(build.id).to eq('abc123')
    end
  end
end
