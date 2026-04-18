# frozen_string_literal: true

require 'saturnci-sdk'
require 'webmock/rspec'

describe SaturnCI::Client do
  describe '#authenticated?' do
    context 'when credentials are valid' do
      let(:client) { SaturnCI::Client.new(user_id: 'test_user', api_token: 'test_token') }

      it 'returns true' do
        stub_request(:get, 'https://app.saturnci.com/api/v1/test_suite_runs')
          .to_return(status: 200)

        expect(client.authenticated?).to be true
      end
    end

    context 'when credentials are missing' do
      let(:client) { SaturnCI::Client.new(user_id: nil, api_token: nil) }

      it "prints 'Credentials not found'" do
        expect { client.authenticated? }.to output(/Credentials not found/).to_stdout
      end

      it 'returns false' do
        allow(client).to receive(:puts)
        expect(client.authenticated?).to be false
      end
    end
  end
end
