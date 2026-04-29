# frozen_string_literal: true

require 'fileutils'
require 'saturnci/minitest_reporter'

module Minitest
  def self.plugin_saturnci_init(_options)
    output_path = ENV.fetch('SATURNCI_MINITEST_OUTPUT_PATH', nil)
    return unless output_path

    FileUtils.mkdir_p(File.dirname(output_path))
    Minitest.reporter << SaturnCI::MinitestReporter.new(File.open(output_path, 'w'))
  end
end
