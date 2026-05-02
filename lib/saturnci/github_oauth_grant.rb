# frozen_string_literal: true

module SaturnCI
  class GitHubOAuthGrant
    def self.destroy(client:)
      client.delete('/api/v1/github_oauth_grant')
    end
  end
end
