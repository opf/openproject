module Unicorn::WorkerKiller
  class Configuration
    attr_accessor :max_quit, :max_term, :sleep_interval

    def initialize
      self.max_quit = 10
      self.max_term = 15
      self.sleep_interval = 1
    end
  end
end
