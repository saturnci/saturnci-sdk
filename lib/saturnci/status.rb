# frozen_string_literal: true

module SaturnCI
  # The API speaks JSON, which has no symbols, so it sends statuses as strings
  # like "Passed" and "Timed Out". Ruby callers expect symbols.
  module Status
    def self.from_api(value)
      return if value.nil?

      value.to_s.downcase.tr(' ', '_').to_sym
    end

    def passed?
      Status.from_api(status) == :passed
    end

    def failed?
      Status.from_api(status) == :failed
    end
  end
end
