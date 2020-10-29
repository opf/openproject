require 'delegate'

module OkComputer
  # This check wraps another check and forces it to be successful so as to
  # avoid triggering alerts.
  class OptionalCheck < SimpleDelegator
    # Public: Always successful
    def success?
      true
    end

    # Public: The text output of performing the check
    #
    # Returns a String
    def to_text
      "#{__getobj__.to_text} (OPTIONAL)"
    end
  end
end
