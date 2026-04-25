# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::ContainerImageBuild do
  describe '.create' do
    it 'posts to the container_image_builds endpoint and returns a container image build with an id' do
      client = SaturnCI::Client.new(TestHelpers.credentials)

      stub_request(:post, 'https://app.saturnci.com/api/v1/container_image_builds')
        .to_return(status: 201, body: '{"id": "abc123"}')

      container_image_build = SaturnCI::ContainerImageBuild.create(
        client: client, repository: 'saturnci/saturnci', name: 'production'
      )

      expect(container_image_build.id).to eq('abc123')
    end
  end

  describe '#wait_for_completion' do
    it 'polls until the container image build is finished and returns the response' do
      client = SaturnCI::Client.new(TestHelpers.credentials)

      stub_request(:post, 'https://app.saturnci.com/api/v1/container_image_builds')
        .to_return(status: 201, body: '{"id": "abc123"}')

      stub_request(:get, 'https://app.saturnci.com/api/v1/container_image_builds/abc123')
        .to_return(
          { status: 200, body: '{"id": "abc123", "status": null}' },
          { status: 200, body: '{"id": "abc123", "status": "Running"}' },
          { status: 200, body: '{"id": "abc123", "status": "Passed"}' }
        )

      container_image_build = SaturnCI::ContainerImageBuild.create(
        client: client, repository: 'saturnci/saturnci', name: 'production'
      )
      allow(container_image_build).to receive(:sleep)
      response = container_image_build.wait_for_completion

      expect(response['status']).to eq('Passed')
    end

    it 'populates container_image_url after finishing' do
      response = double(body: '{"status": "Passed", "container_image_url": "registry.example.com/image:latest"}')
      client = double(get: response)

      container_image_build = SaturnCI::ContainerImageBuild.new(id: 'abc123', client: client)

      expect(container_image_build.container_image_url).to be_nil

      container_image_build.wait_for_completion

      expect(container_image_build.container_image_url).to eq('registry.example.com/image:latest')
    end
  end

  describe '#url' do
    it 'populates url from the API response' do
      stub_request(:post, 'https://app.saturnci.com/api/v1/container_image_builds')
        .to_return(status: 201, body: '{"id": "abc123", "url": "https://app.saturnci.com/container_image_builds/abc123"}')

      client = SaturnCI::Client.new(TestHelpers.credentials)
      container_image_build = SaturnCI::ContainerImageBuild.create(
        client: client, repository: 'saturnci/saturnci', name: 'production'
      )

      expect(container_image_build.url).to eq('https://app.saturnci.com/container_image_builds/abc123')
    end
  end
end
