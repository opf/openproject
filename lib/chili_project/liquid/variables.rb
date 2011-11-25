module ChiliProject
  module Liquid
    module Variables
      # Liquid "variables" that are used for backwards compatability with macros
      #
      # Variables are used in liquid like {{var}}
      def self.macro_backwards_compatibility
        {
          'macro_list' => "Use the '{% variable_list %}' tag to see all Liquid variables and '{% tag_list %}' to see all of the Liquid tags."
        }
      end
    end
  end
end
