# frozen_string_literal: true

require 'json'
require 'stringio'
require 'saturnci-sdk'
require 'saturnci/minitest_reporter'
require 'spec_helper'

describe SaturnCI::MinitestReporter do
  describe '#report' do
    context 'when one passing test was recorded' do
      let(:output) { StringIO.new }
      let(:reporter) { SaturnCI::MinitestReporter.new(output) }
      let(:result) do
        double(
          'Minitest::Result',
          name: 'test_foo',
          klass: 'MyTest',
          failure: nil,
          time: 0.01,
          source_location: ['my_test.rb', 5]
        )
      end
      let(:examples) { JSON.parse(output.string)['examples'] }

      before do
        reporter.record(result)
        reporter.report
      end

      it "writes one example with the test's id to the output" do
        expect(examples.first['id']).to eq('MyTest#test_foo')
      end

      it "writes 'passed' as the example's status" do
        expect(examples.first['status']).to eq('passed')
      end

      it "writes the test's file path" do
        expect(examples.first['file_path']).to eq('my_test.rb')
      end

      it "writes the test's line number" do
        expect(examples.first['line_number']).to eq(5)
      end

      it "writes the test's run time" do
        expect(examples.first['run_time']).to eq(0.01)
      end

      it "writes the test's full description" do
        expect(examples.first['full_description']).to eq('MyTest#test_foo')
      end
    end

    context 'when one failing test was recorded' do
      let(:output) { StringIO.new }
      let(:reporter) { SaturnCI::MinitestReporter.new(output) }
      let(:result) do
        double(
          'Minitest::Result',
          name: 'test_foo',
          klass: 'MyTest',
          failure: double('Minitest::Assertion', message: 'expected true'),
          time: 0.01,
          source_location: ['my_test.rb', 5]
        )
      end
      let(:examples) { JSON.parse(output.string)['examples'] }

      before do
        reporter.record(result)
        reporter.report
      end

      it "writes 'failed' as the example's status" do
        expect(examples.first['status']).to eq('failed')
      end
    end
  end
end
