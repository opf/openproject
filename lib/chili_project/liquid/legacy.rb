module ChiliProject
  module Liquid
    # Legacy is used to support older Redmine style macros by converting
    # them to Liquid objects (tags, filters) on the fly by doing basic
    # string substitution. This is done before the Liquid processing
    # so the converted macros work like normal
    #
    module Legacy
      # Holds the list of legacy macros
      #
      # @param [Regexp] :match The regex to match on the legacy macro
      # @param [String] :replace The string to replace with. E.g. "%" converts
      #        "{{ }}" to "{% %}"
      # @param [String] :new_name The new name of the Liquid object
      def self.macros
        @macros ||= {}
      end

      # "Runs" legacy macros by doing a gsub of their values to the new Liquid ones
      #
      # @param [String] content The pre-Liquid content
      def self.run_macros(content)
        macros.each do |macro_name, macro|
          next unless macro[:match].present? && macro[:replace].present?
          content.gsub!(macro[:match]) do |match|
            # Use block form so $1 and $2 are set properly
            "{#{macro[:replace]} #{macro[:new_name]} '#{$2}' #{macro[:replace]}}"
          end
        end
      end

      # Add support for a legacy macro syntax that was converted to liquid
      #
      # @param [String] name The legacy macro name
      # @param [Symbol] liquid_type The type of Liquid object to use. Supported: :tag
      # @param [optional, String] new_name The new name of the liquid object, used
      #        to rename a macro
      def self.add(name, liquid_type, new_name=nil)
        new_name = name unless new_name.present?
        case liquid_type
        when :tag

          macros[name.to_s] = {
            # Example values the regex matches
            # {{name}}
            # {{ name }}
            # {{ name 'arg' }}
            # {{ name('arg') }}
            :match => Regexp.new(/\{\{(#{name})(?:\(([^\}]*)\))?\}\}/),
            :replace => "%",
            :new_name => new_name
          }
        end
      end
    end
  end
end
