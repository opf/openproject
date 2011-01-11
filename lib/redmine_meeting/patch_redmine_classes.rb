module Plugin
  module Meeting
    module Project
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          #unloadable
          has_many :meetings, :include => [:author]
        end
      end
    end    
  end
end