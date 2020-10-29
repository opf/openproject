module OkComputer
  class DefaultCheck < Check
    # Public: Check that Rails can render anything at all
    def check
      mark_message "Application is running"
    end
  end
end
