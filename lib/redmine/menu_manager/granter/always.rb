module Redmine
  module MenuManager
    module Granter
      class Always
        def self.call(*args)
          true
        end
      end
    end
  end
end
