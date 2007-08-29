module Redmine
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 5
    TINY  = 1

    STRING= [MAJOR, MINOR, TINY].join('.')
    
    def self.to_s; STRING end    
  end
  
  module Info
    class << self
      def name; 'Redmine' end
      def url; 'http://www.redmine.org/' end
    end
  end
end
