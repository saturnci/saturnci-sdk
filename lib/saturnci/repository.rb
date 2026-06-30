# frozen_string_literal: true

module SaturnCI
  class Repository
    attr_reader :github_repo_full_name, :github_installation_id

    def initialize(github_repo_full_name:, github_installation_id:)
      @github_repo_full_name = github_repo_full_name
      @github_installation_id = github_installation_id
    end
  end
end
