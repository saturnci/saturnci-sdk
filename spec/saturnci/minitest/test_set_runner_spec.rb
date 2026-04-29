# frozen_string_literal: true

require 'json'
require 'saturnci/minitest/test_set_runner'
require 'spec_helper'

describe SaturnCI::Minitest::TestSetRunner do
  describe '.json_for' do
    context 'with a test set containing one identifier and one file path' do
      it 'produces JSON containing both the identifiers list and the file_paths_by_identifier hash' do
        test_set = SaturnCI::Minitest::TestSet.new(
          test_classes: [
            {
              name: 'NumbersTest',
              method_names: %w[test_sum],
              file_path: 'test/numbers_test.rb'
            }
          ]
        )

        json = SaturnCI::Minitest::TestSetRunner.json_for(test_set)

        expect(JSON.parse(json)).to eq(
          'identifiers' => ['NumbersTest#test_sum'],
          'file_paths_by_identifier' => { 'NumbersTest#test_sum' => 'test/numbers_test.rb' }
        )
      end
    end
  end
end
