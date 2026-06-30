# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'
require 'spec_helper'

describe SaturnCI::Environment do
  describe '#github_token' do
    it 'posts the installation id and returns the token' do
      client = SaturnCI::Client.new(double(api_token: 'x'))
      repository = SaturnCI::Repository.new(github_repo_full_name: 'saturnci/saturnci',
                                            github_installation_id: '12345678')
      job_run = double('job_run', repository: repository)
      environment = SaturnCI::Environment.new(job_run: job_run, client: client)

      stub_request(:post, 'https://app.saturnci.com/api/v1/task_agents/github_tokens')
        .with(body: { 'github_installation_id' => '12345678' })
        .to_return(status: 200, body: 'ghs_sometoken')

      expect(environment.github_token).to eq('ghs_sometoken')
    end
  end

  describe '#file_exists?' do
    it 'is true when the path exists on the filesystem' do
      environment = SaturnCI::Environment.new(job_run: double, client: double)
      allow(File).to receive(:exist?).with('/pipeline-workspaces/root123').and_return(true)

      expect(environment.file_exists?('/pipeline-workspaces/root123')).to be(true)
    end

    it 'is false when the path does not exist on the filesystem' do
      environment = SaturnCI::Environment.new(job_run: double, client: double)
      allow(File).to receive(:exist?).with('/pipeline-workspaces/root123').and_return(false)

      expect(environment.file_exists?('/pipeline-workspaces/root123')).to be(false)
    end
  end

  describe '#clone_repo' do
    let(:client) { SaturnCI::Client.new(double(api_token: 'x')) }
    let(:repository) do
      SaturnCI::Repository.new(github_repo_full_name: 'saturnci/saturnci',
                               github_installation_id: '12345678')
    end
    let(:job_run) do
      double('job_run', repository: repository, pipeline_workspace_dir: '/pipeline-workspaces/root123')
    end
    let(:shell) { spy('shell') }
    let(:environment) { SaturnCI::Environment.new(job_run: job_run, client: client, shell: shell) }

    before do
      stub_request(:post, 'https://app.saturnci.com/api/v1/task_agents/github_tokens')
        .to_return(status: 200, body: 'ghs_sometoken')
      allow(Dir).to receive(:exist?).with('/pipeline-workspaces/root123').and_return(true)
      allow(Dir).to receive(:empty?).with('/pipeline-workspaces/root123').and_return(false)
    end

    it 'clones the repository into the pipeline workspace over an authenticated github url' do
      environment.clone_repo

      expect(shell).to have_received(:execute).with(
        'git ' \
        '-c url."https://x-access-token:ghs_sometoken@github.com/".insteadOf="https://github.com/" ' \
        '-c url."https://x-access-token:ghs_sometoken@github.com/".insteadOf="git@github.com:" ' \
        'clone --recurse-submodules https://github.com/saturnci/saturnci /pipeline-workspaces/root123'
      )
    end

    it 'returns the pipeline workspace dir it cloned into' do
      expect(environment.clone_repo).to eq('/pipeline-workspaces/root123')
    end

    it 'raises when the cloned content is not readable at the destination' do
      allow(Dir).to receive(:exist?).with('/pipeline-workspaces/root123').and_return(false)

      expect { environment.clone_repo }.to raise_error(
        %r{pipeline workspace not readable.*/pipeline-workspaces/root123}
      )
    end

    it 'raises when the destination is empty after cloning' do
      allow(Dir).to receive(:empty?).with('/pipeline-workspaces/root123').and_return(true)

      expect { environment.clone_repo }.to raise_error(
        %r{pipeline workspace not readable.*/pipeline-workspaces/root123}
      )
    end
  end
end
