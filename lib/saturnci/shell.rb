# frozen_string_literal: true

require 'English'

module SaturnCI
  class Shell
    def execute(command)
      return if system(command)

      raise "command failed (exit status: #{$CHILD_STATUS.exitstatus}): #{command}"
    end
  end
end
