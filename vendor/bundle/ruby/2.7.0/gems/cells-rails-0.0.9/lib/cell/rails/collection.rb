module Cell
  module RailsExtension
    module Collection
      def call(*)
        super.html_safe
      end
    end
  end
end
