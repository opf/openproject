module Redmine
  module Activity
  
    mattr_accessor :available_event_types, :default_event_types, :providers
    
    @@available_event_types = []
    @@default_event_types = []
    @@providers = Hash.new {|h,k| h[k]=[] }

    class << self
      def map(&block)
        yield self
      end
      
      # Registers an activity provider
      def register(event_type, options={})
        options.assert_valid_keys(:class_name, :default)
        
        event_type = event_type.to_s
        providers = options[:class_name] || event_type.classify
        providers = ([] << providers) unless providers.is_a?(Array)
        
        @@available_event_types << event_type unless @@available_event_types.include?(event_type)
        @@default_event_types << event_type unless options[:default] == false
        @@providers[event_type] += providers
      end
    end
  end
end
