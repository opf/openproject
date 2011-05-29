module Redmine
  module Platform
    class << self
      def mswin?
        (RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
      end
    end
  end
end
