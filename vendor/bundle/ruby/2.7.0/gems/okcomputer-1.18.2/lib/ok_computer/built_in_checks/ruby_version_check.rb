module OkComputer
  class RubyVersionCheck < Check
    def check
      mark_message "Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
    end
  end
end
