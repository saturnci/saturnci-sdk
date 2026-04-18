# frozen_string_literal: true

require 'saturnci-sdk'

describe SaturnCI::Client do
  describe '#authenticated?' do
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
