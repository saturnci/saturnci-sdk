# frozen_string_literal: true

require 'saturnci-sdk'
require 'spec_helper'

describe SaturnCI::Shell do
  describe '#execute' do
    it 'runs the command without raising on success' do
      expect { SaturnCI::Shell.new.execute('true') }.not_to raise_error
    end

    it 'raises when the command fails' do
      expect { SaturnCI::Shell.new.execute('false') }.to raise_error(/command failed/)
    end
  end
end
