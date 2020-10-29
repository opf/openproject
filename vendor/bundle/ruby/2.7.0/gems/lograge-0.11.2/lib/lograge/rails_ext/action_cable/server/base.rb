module ActionCable
  module Server
    class Base
      mattr_accessor :logger
      self.logger = Lograge::SilentLogger.new(config.logger)
    end
  end
end
