# frozen_string_literal: true

require 'json'

module SaturnCI
  class MinitestReporter
    def initialize(output)
      @output = output
      @results = []
    end

    def start; end

    def prerecord(klass, name); end

    def record(result)
      @results << result
    end

    def report
      examples = @results.map do |result|
        {
          'id' => "#{result.klass}##{result.name}",
          'status' => result.failure ? 'failed' : 'passed'
        }
      end
      @output.write(JSON.generate('examples' => examples))
    end

    def passed?
      @results.none?(&:failure)
    end
  end
end
