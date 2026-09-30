# frozen_string_literal: true

require 'spec_helper'
load File.expand_path(
  '../../.saturnci/jobs/workflow_environment_image_build/workflow_environment_image_build_job.rb', __dir__
)

describe WorkflowEnvironmentImageBuild do
  let!(:env) do
    {
      'DOCKER_REGISTRY_URL' => 'registry.example.com',
      'DOCKER_IMAGE_NAME' => 'saturnci/workflow-environment',
      'DOCKER_REGISTRY_USERNAME' => 'someone@example.com',
      'DOCKER_REGISTRY_PASSWORD' => 'dop_secret'
    }
  end

  context 'when the version has not been published yet' do
    it 'pushes an image tagged with the version' do
      shell = double('shell', run: true, tag_exists?: false)

      WorkflowEnvironmentImageBuild.new(env: env, shell: shell, version: '1.0.0', io: StringIO.new).perform

      expect(shell).to have_received(:run).with(
        a_string_including('docker push registry.example.com/saturnci/workflow-environment:v1.0.0')
      )
    end
  end

  context 'when the version has already been published' do
    it 'pushes nothing' do
      shell = double('shell', run: true, tag_exists?: true)

      WorkflowEnvironmentImageBuild.new(env: env, shell: shell, version: '1.0.0', io: StringIO.new).perform

      expect(shell).not_to have_received(:run).with(a_string_including('docker push'))
    end
  end
end
