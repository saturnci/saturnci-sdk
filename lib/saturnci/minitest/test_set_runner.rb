# frozen_string_literal: true

require 'json'
require 'minitest'
require 'saturnci/minitest/test_set'

module SaturnCI
  module Minitest
    class TestSetRunner
      DEFAULT_TEST_FILES_GLOB = 'test/**/*_test.rb'
      LOG_PREFIX = '[saturnci.test_set_runner]'

      def self.perform(test_files_glob: DEFAULT_TEST_FILES_GLOB)
        new(test_files_glob: test_files_glob).perform
      end

      def initialize(test_files_glob:)
        @test_files_glob = test_files_glob
      end

      def perform
        log 'starting'
        ::Minitest.seed = 0 unless ::Minitest.seed
        load_test_files
        log 'all test files loaded'
        write_json
        log "wrote #{test_set.identifiers.count} identifiers"
      end

      private

      def load_test_files
        files = Dir[@test_files_glob]
        log "loading #{files.count} test files"
        files.each_with_index do |file, i|
          log "loading (#{i + 1}/#{files.count}): #{file}"
          require_relative File.expand_path(file)
        end
      end

      def test_set
        @test_set ||= TestSet.from_runnables(::Minitest::Runnable.runnables, exclude: exclude)
      end

      def exclude
        excluded = [::Minitest::Test]
        excluded << ActiveSupport::TestCase if defined?(ActiveSupport::TestCase)
        excluded
      end

      def write_json
        File.write(json_output_path, JSON.generate(identifiers: test_set.identifiers))
      end

      def json_output_path
        ENV.fetch('SATURNCI_TEST_SET_JSON_PATH', 'tmp/saturnci_test_set.json')
      end

      def log(message)
        # No-op: deliberately not writing to any IO stream.
      end
    end
  end
end
