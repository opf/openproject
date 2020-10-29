require "benchmark"

module OkComputer
  class Check
    # to be set by Registry upon registration
    attr_accessor :registrant_name
    # nil by default, only set to true if the check deems itself failed
    attr_accessor :failure_occurred
    # nil by default, set by #check to control the output
    attr_accessor :message
    # Float::NAN by default, set by #run to the elapsed time to run #check
    attr_accessor :time

    # Public: Run the check
    def run
      clear
      with_benchmarking do
        check
      end
      OkComputer.logger.info "[okcomputer] #{to_text}"
    end

    # Private: Perform the appropriate check
    #
    # Your subclass of Check must define its own #check method. This method
    # must return the string to render when performing the check.
    def check
      raise(CheckNotDefined, "Your subclass must define its own #check.")
    end
    private :check

    # Public: The text output of performing the check
    #
    # Returns a String
    def to_text
      passfail = success? ? "passed" : "failed"
      I18n.t("okcomputer.check.#{passfail}", registrant_name: registrant_name, message: message, time: "#{time ? sprintf('%.3f', time) : '?'}s")
    end

    # Public: The JSON output of performing the check
    #
    # Returns a String containing JSON
    def to_json(*args)
      # NOTE swallowing the arguments that Rails passes by default since we don't care. This may prove to be a bad idea
      # Rails passes stuff like this: {:prefixes=>["ok_computer", "application"], :template=>"show", :layout=>#<Proc>}]
      {registrant_name => {:message => message, :success => success?, :time => time}}.to_json
    end

    def <=>(check)
      if check.is_a?(CheckCollection)
        -1
      else
        registrant_name.to_s <=> check.registrant_name.to_s
      end
    end

    # Public: Whether the check passed
    #
    # Returns a boolean
    def success?
      not failure_occurred
    end

    # Public: Mark that this check has failed in some way
    def mark_failure
      self.failure_occurred = true
    end

    # Public: Capture the desired message to display
    #
    # message - Text of the message to display for this check
    def mark_message(message)
      self.message = message
    end

    # Public: Clear any prior failures
    def clear
      self.failure_occurred = false
      self.message = nil
      self.time = Float::NAN
    end

    # Private: Benchmark the time it takes to run the block
    def with_benchmarking
      self.time = Benchmark.realtime do
        yield
      end
    end

    CheckNotDefined = Class.new(StandardError)
  end
end
