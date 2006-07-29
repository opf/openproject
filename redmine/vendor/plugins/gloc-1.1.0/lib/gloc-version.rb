module GLoc
  module VERSION #:nodoc:
    MAJOR = 1
    MINOR = 1
    TINY  = nil

    STRING= [MAJOR, MINOR, TINY].delete_if{|x|x.nil?}.join('.')
    def self.to_s; STRING end
  end
end

puts "NOTICE: You are using a dev version of GLoc." if GLoc::VERSION::TINY == 'DEV'