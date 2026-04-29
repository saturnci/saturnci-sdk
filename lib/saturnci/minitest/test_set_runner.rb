# frozen_string_literal: true

require 'json'
require 'minitest'
require 'saturnci/minitest/test_set'

module SaturnCI
  module Minitest
    class TestSetRunner
      DEFAULT_TEST_FILES_GLOB = 'test/**/*_test.rb'

      def self.call(test_files_glob: DEFAULT_TEST_FILES_GLOB, output: $stdout, log: $stderr)
        new(test_files_glob: test_files_glob, output: output, log: log).call
      end

      def initialize(test_files_glob:, output:, log:)
        @test_files_glob = test_files_glob
        @output = output
        @log = log
        @log.sync = true if @log.respond_to?(:sync=)
      end

      def call
        $stdout.sync = true
        $stderr.sync = true
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
        @output.write(JSON.generate(identifiers: test_set.identifiers))
        @output.write("\n")
        @output.flush if @output.respond_to?(:flush)
      end

      def log(message)
        @log.puts "[saturnci.test_set_runner] #{message}"
      end
    end
  end
end
