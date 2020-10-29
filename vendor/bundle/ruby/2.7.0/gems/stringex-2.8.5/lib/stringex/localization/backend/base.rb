module Stringex
  module Localization
    module Backend
      class Base
        class << self
          def reset!
            instance_variables.each { |var| remove_instance_variable var }
          end
        end
      end
    end
  end
end