require 'blankslate'

module Redmine
  module Views
    module Builders
      class Structure < BlankSlate
        def initialize
          @struct = [{}]
        end
        
        def array(tag, options={}, &block)
          @struct << []
          block.call(self)
          ret = @struct.pop
          @struct.last[tag] = ret
          @struct.last.merge!(options) if options
        end
        
        def method_missing(sym, *args, &block)
          if args.any?
            if args.first.is_a?(Hash)
              if @struct.last.is_a?(Array)
                @struct.last << args.first unless block
              else
                @struct.last[sym] = args.first
              end
            else
              if @struct.last.is_a?(Array)
                @struct.last << (args.last || {}).merge(:value => args.first)
              else
                @struct.last[sym] = args.first
              end
            end
          end
          
          if block
            @struct << (args.first.is_a?(Hash) ? args.first : {})
            block.call(self)
            ret = @struct.pop
            if @struct.last.is_a?(Array)
              @struct.last << ret
            else
              if @struct.last.has_key?(sym) && @struct.last[sym].is_a?(Hash)
                @struct.last[sym].merge! ret
              else
                @struct.last[sym] = ret
              end
            end
          end
        end
        
        def output
          raise "Need to implement #{self.class.name}#output"
        end
      end
    end
  end
end
