# frozen_string_literal: true

require 'saturnci/minitest/test_set'
require 'spec_helper'

describe SaturnCI::Minitest::TestSet do
  describe '#identifiers' do
    context 'with no test classes' do
      it 'returns an empty list' do
        test_set = SaturnCI::Minitest::TestSet.new(test_classes: [])
        expect(test_set.identifiers).to eq([])
      end
    end

    context 'with one test class with one method' do
      it 'returns one identifier' do
        test_classes = [{ name: 'NumbersTest', method_names: ['test_sum'] }]
        test_set = SaturnCI::Minitest::TestSet.new(test_classes: test_classes)
        expect(test_set.identifiers).to eq(['NumbersTest#test_sum'])
      end
    end

    context 'with one test class with multiple methods' do
      it 'returns one identifier per method' do
        test_classes = [{ name: 'NumbersTest', method_names: %w[test_sum test_product] }]
        test_set = SaturnCI::Minitest::TestSet.new(test_classes: test_classes)
        expect(test_set.identifiers).to eq(%w[NumbersTest#test_sum NumbersTest#test_product])
      end
    end

    context 'with multiple test classes' do
      it 'returns a flattened list of identifiers' do
        test_classes = [
          { name: 'NumbersTest', method_names: %w[test_sum] },
          { name: 'WordsTest', method_names: %w[test_count] }
        ]
        test_set = SaturnCI::Minitest::TestSet.new(test_classes: test_classes)
        expect(test_set.identifiers).to eq(%w[NumbersTest#test_sum WordsTest#test_count])
      end
    end
  end

  describe '#file_paths_by_identifier' do
    context 'with one test class with two methods defined in one file' do
      it 'returns a hash mapping each identifier to that file path' do
        test_classes = [
          {
            name: 'NumbersTest',
            method_names: %w[test_sum test_product],
            file_path: 'test/numbers_test.rb'
          }
        ]
        test_set = SaturnCI::Minitest::TestSet.new(test_classes: test_classes)
        expect(test_set.file_paths_by_identifier).to eq(
          'NumbersTest#test_sum' => 'test/numbers_test.rb',
          'NumbersTest#test_product' => 'test/numbers_test.rb'
        )
      end
    end
  end

  describe '.from_runnables' do
    let(:runnable) do
      Class.new do
        def self.name
          'NumbersTest'
        end

        def self.runnable_methods
          %w[test_sum]
        end
      end
    end

    it "produces a TestSet whose identifiers reflect the runnable's class name and methods" do
      test_set = SaturnCI::Minitest::TestSet.from_runnables([runnable])
      expect(test_set.identifiers).to eq(%w[NumbersTest#test_sum])
    end

    it 'excludes runnables listed in the exclude argument' do
      excluded = Class.new do
        def self.name
          'BaseTest'
        end

        def self.runnable_methods
          %w[test_should_not_appear]
        end
      end

      test_set = SaturnCI::Minitest::TestSet.from_runnables([runnable, excluded], exclude: [excluded])
      expect(test_set.identifiers).to eq(%w[NumbersTest#test_sum])
    end
  end
end
