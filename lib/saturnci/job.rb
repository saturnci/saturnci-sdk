# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module SaturnCI
  class Job
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def self.create(repository:, name:)
      response = post_to_api(repository: repository, name: name)
      body = JSON.parse(response.body)
      new(id: body['id'])
    end

    def self.post_to_api(repository:, name:)
      config = SaturnCI.configuration
      uri = URI("#{config.base_url}/api/v1/jobs")
      req = Net::HTTP::Post.new(uri)
      req.basic_auth(config.user_id, config.api_token)
      req.set_form_data(repository: repository, job_name: name)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
    end
    private_class_method :post_to_api
  end
end
