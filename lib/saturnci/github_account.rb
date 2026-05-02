# frozen_string_literal: true

require 'json'

module SaturnCI
  class GitHubAccount
    attr_reader :id

    def initialize(id:, client:)
      @id = id
      @client = client
    end

    def self.list(client:)
      response = client.get('/api/v1/github_accounts')
      JSON.parse(response.body).map { |github_account| new(id: github_account['id'], client: client) }
    end

    def destroy
      @client.delete("/api/v1/github_accounts/#{@id}")
    end
  end
end
