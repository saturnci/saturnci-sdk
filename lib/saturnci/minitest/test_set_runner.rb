# frozen_string_literal: true

module SaturnCI
  module Minitest
    class TestSetRunner
      def initialize
        puts 'hey1'
      end

      def call
        'hey2'
      end
    end
  end
end
