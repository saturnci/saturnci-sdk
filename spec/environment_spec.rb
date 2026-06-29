# frozen_string_literal: true

require 'saturnci-sdk'
require 'spec_helper'

describe SaturnCI::Environment do
  describe '#clone_repo' do
    it 'runs a git clone in the shell' do
      shell = spy('shell')
      job_run = double('job_run')
      environment = SaturnCI::Environment.new(job_run: job_run, shell: shell)

      environment.clone_repo

      expect(shell).to have_received(:execute).with(a_string_starting_with('git clone'))
    end

    it 'raises when the clone fails' do
      shell = double('shell', execute: false)
      job_run = double('job_run')
      environment = SaturnCI::Environment.new(job_run: job_run, shell: shell)

      expect { environment.clone_repo }.to raise_error(/clone failed/)
    end
  end
end
