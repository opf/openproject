module Mixlib
  class ShellOut
    class ShellCommandFailed < RuntimeError; end
    class CommandTimeout < RuntimeError; end
    class InvalidCommandOption < RuntimeError; end
  end
end
