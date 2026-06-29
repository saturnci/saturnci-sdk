# frozen_string_literal: true

module SaturnCI
  class Shell
    def execute(command)
      system(command)
    end
  end
end
