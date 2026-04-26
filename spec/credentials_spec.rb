# frozen_string_literal: true

require 'saturnci-sdk'

describe SaturnCI::Credentials do
  context 'when no arguments are passed' do
    it 'has the credentials from the credentials file' do
      allow(File).to receive(:read)
        .with(File.expand_path('~/.saturnci/credentials.json'))
        .and_return('{"api_token": "file_token"}')

      credentials = SaturnCI::Credentials.new

      expect(credentials.api_token).to eq('file_token')
    end
  end

  context 'when an api_token is passed' do
    it 'uses the passed api_token without reading the credentials file' do
      expect(File).not_to receive(:read)

      credentials = SaturnCI::Credentials.new(api_token: 'passed_token')

      expect(credentials.api_token).to eq('passed_token')
    end
  end
end
