module Acts::Journalized
  module DataClass
    def self.included(base) # :nodoc:
      base.class_eval do
        class << self
          prepend ClassMethods
        end
      end
    end

    module ClassMethods
      def journal_class
        namespace = name.deconstantize

        if namespace == "Journal"
          self
        else
          "Journal::#{base_class.name}Journal".constantize
        end
      end
    end
  end
end
