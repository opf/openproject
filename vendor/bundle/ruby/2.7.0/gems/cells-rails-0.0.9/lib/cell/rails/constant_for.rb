module Cell
  module RailsExtension
    module ConstantFor
      def constant_for(name)
        name.camelize.constantize
      end
    end
  end
end
