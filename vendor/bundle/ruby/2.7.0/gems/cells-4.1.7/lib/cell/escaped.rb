module Cell::ViewModel::Escaped
  def self.included(includer)
    includer.extend Property
  end

  module Property
    def property(*names)
      super.tap do # super defines #title
        mod = Module.new do
          names.each do |name|
            define_method(name) do |options={}|
              value = super() # call the original #title.
              return value unless value.is_a?(String)
              return value if options[:escape] == false
              escape!(value)
            end
          end
        end
        include mod
      end
    end
  end # Property

  # Can be used as a helper in the cell, too.
  # Feel free to override and use a different escaping implementation.
  require "erb"
  def escape!(string)
    ::ERB::Util.html_escape(string)
  end
end
