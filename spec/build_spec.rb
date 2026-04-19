# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::Build do
  describe '.create' do
    it 'posts to the builds endpoint and returns a build with an id' do
      client = SaturnCI::Client.new(TestHelpers.credentials)

      stub_request(:post, 'https://app.saturnci.com/api/v1/builds')
        .to_return(status: 201, body: '{"id": "abc123"}')

      build = SaturnCI::Build.create(client: client, repository: 'saturnci/saturnci', name: 'production')

      expect(build.id).to eq('abc123')
    end
  end

  describe '#wait_for_completion' do
    it 'polls until the build is finished and returns the response' do
      client = SaturnCI::Client.new(TestHelpers.credentials)

      stub_request(:post, 'https://app.saturnci.com/api/v1/builds')
        .to_return(status: 201, body: '{"id": "abc123"}')

      stub_request(:get, 'https://app.saturnci.com/api/v1/builds/abc123')
        .to_return(
          { status: 200, body: '{"id": "abc123", "status": null}' },
          { status: 200, body: '{"id": "abc123", "status": "Running"}' },
          { status: 200, body: '{"id": "abc123", "status": "Passed"}' }
        )

      build = SaturnCI::Build.create(client: client, repository: 'saturnci/saturnci', name: 'production')
      allow(build).to receive(:sleep)
      response = build.wait_for_completion

      expect(response['status']).to eq('Passed')
    end

    it 'populates container_image_url after finishing' do
      response = double(body: '{"status": "Passed", "container_image_url": "registry.example.com/image:latest"}')
      client = double(get: response)

      build = SaturnCI::Build.new(id: 'abc123', client: client)

      expect(build.container_image_url).to be_nil

      build.wait_for_completion

      expect(build.container_image_url).to eq('registry.example.com/image:latest')
    end
  end

  describe '#url' do
    it 'populates url from the API response' do
      stub_request(:post, 'https://app.saturnci.com/api/v1/builds')
        .to_return(status: 201, body: '{"id": "abc123", "url": "https://app.saturnci.com/builds/abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      build = SaturnCI::Build.create(client: client, repository: 'saturnci/saturnci', name: 'production')

      expect(build.url).to eq('https://app.saturnci.com/builds/abc123')
    end
  end
end
