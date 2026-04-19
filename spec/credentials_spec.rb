# frozen_string_literal: true

require 'saturnci-sdk'

describe SaturnCI::Credentials do
  context 'when no arguments are passed' do
    it 'has the credentials from the credentials file' do
      allow(File).to receive(:read)
        .with(File.expand_path('~/.saturnci/credentials.json'))
        .and_return('{"user_id": "file_user", "api_token": "file_token"}')

      credentials = SaturnCI::Credentials.new

      expect(credentials.user_id).to eq('file_user')
      expect(credentials.api_token).to eq('file_token')
    end
  end
end
