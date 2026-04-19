# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Client do
  describe '#authenticated?' do
    context 'when credentials are valid' do
      let(:client) { SaturnCI::Client.new(double(user_id: 'x', api_token: 'x')) }

      it 'returns true' do
        stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs')
          .to_return(status: 200)

        expect(client.authenticated?).to be true
      end
    end

    context 'when created with a Credentials object' do
      it 'uses the credentials for authentication' do
        credentials = double(user_id: 'x', api_token: 'x')
        client = SaturnCI::Client.new(credentials)

        stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs')
          .to_return(status: 200)

        expect(client.authenticated?).to be true
      end
    end

    context 'when no credentials are passed' do
      it 'reads credentials from the credentials file' do
        allow(File).to receive(:read)
          .with(File.expand_path('~/.saturnci/credentials.json'))
          .and_return('{"user_id": "file_user", "api_token": "file_token"}')

        stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs')
          .to_return(status: 200)

        expect(SaturnCI::Client.new.authenticated?).to be true
      end
    end

    context 'when credentials are missing' do
      let(:client) { SaturnCI::Client.new(double(user_id: nil, api_token: nil)) }

      it 'returns false' do
        expect(client.authenticated?).to be false
      end
    end
  end
end
