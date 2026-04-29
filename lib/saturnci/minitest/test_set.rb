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
    end
  end
end
