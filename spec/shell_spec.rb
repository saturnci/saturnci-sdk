# frozen_string_literal: true

require 'saturnci-sdk'
require 'spec_helper'

describe SaturnCI::Shell do
  describe '#execute' do
    it 'runs the command and returns true on success' do
      expect(SaturnCI::Shell.new.execute('true')).to eq(true)
    end

    it 'returns false on failure' do
      expect(SaturnCI::Shell.new.execute('false')).to eq(false)
    end
  end
end
