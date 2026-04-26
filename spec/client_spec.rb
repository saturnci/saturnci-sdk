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

    context 'when credentials are missing' do
      let(:client) { SaturnCI::Client.new(double(user_id: nil, api_token: nil)) }

      it 'returns false' do
        expect(client.authenticated?).to be false
      end
    end
  end

  describe 'authentication header' do
    context 'when credentials have only an api_token' do
      it 'sends Authorization: Bearer <api_token>' do
        client = SaturnCI::Client.new(double(user_id: nil, api_token: 'abc123'))

        stub = stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs')
               .with(headers: { 'Authorization' => 'Bearer abc123' })
               .to_return(status: 200)

        client.get('/api/v1/test_suite_runs')

        expect(stub).to have_been_requested
      end
    end
  end
end
