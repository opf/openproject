require 'blankslate'

module Redmine
  module Views
    module Builders
      class Json < Structure
        def output
          @struct.first.to_json
        end
      end
    end
  end
end
