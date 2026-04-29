# frozen_string_literal: true

module SaturnCI
  module Minitest
    class TestSet
      def self.from_runnables(runnables, exclude: [])
        included = runnables - exclude
        new(test_classes: included.map { |r| { name: r.name, method_names: r.runnable_methods } })
      end

      def initialize(test_classes:)
        @test_classes = test_classes
      end

      def identifiers
        @test_classes.flat_map do |test_class|
          test_class[:method_names].map { |method_name| "#{test_class[:name]}##{method_name}" }
        end
      end

      def file_paths_by_identifier
        @test_classes.each_with_object({}) do |test_class, result|
          test_class[:method_names].each do |method_name|
            result["#{test_class[:name]}##{method_name}"] = test_class[:file_path]
          end
        end
      end
    end
  end
end
