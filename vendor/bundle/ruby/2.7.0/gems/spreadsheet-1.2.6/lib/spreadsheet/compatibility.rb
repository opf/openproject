module Spreadsheet
  module Compatibility
    ##
    # One of the most incisive changes in terms of meta-programming in Ruby 1.9
    # is the switch from representing instance-variable names as Strings to
    # presenting them as Symbols. ivar_name provides compatibility.
    if RUBY_VERSION >= '1.9'
      def ivar_name symbol
        :"@#{symbol}"
      end
      def method_name symbol
        symbol.to_sym
      end
    else
      def ivar_name symbol
        "@#{symbol}"
      end
      def method_name symbol
        symbol.to_s
      end
    end
  end
end
