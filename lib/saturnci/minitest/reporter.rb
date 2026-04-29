# frozen_string_literal: true

require 'json'
require 'pathname'

module SaturnCI
  module Minitest
    class Reporter
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
        @output.write(JSON.generate('examples' => @results.map { |result| example_for(result) }))
      end

      def passed?
        @results.none?(&:failure)
      end

      private

      def example_for(result)
        id = "#{result.klass}##{result.name}"
        {
          'id' => id,
          'status' => result.failure ? 'failed' : 'passed',
          'file_path' => relative_file_path(result.source_location[0]),
          'line_number' => result.source_location[1],
          'run_time' => result.time,
          'full_description' => id
        }
      end

      def relative_file_path(path)
        Pathname.new(path).relative_path_from(Dir.pwd).to_s
      rescue ArgumentError
        path
      end
    end
  end
end
