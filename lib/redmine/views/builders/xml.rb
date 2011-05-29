module Redmine
  module Views
    module Builders
      class Xml < ::Builder::XmlMarkup
        def initialize
          super
          instruct!
        end
        
        def output
          target!
        end
        
        def method_missing(sym, *args, &block)
          if args.size == 1 && args.first.is_a?(Time)
            __send__ sym, args.first.xmlschema, &block
          else
            super
          end
        end
        
        def array(name, options={}, &block)
          __send__ name, (options || {}).merge(:type => 'array'), &block
        end
      end
    end
  end
end
