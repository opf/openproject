#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'blankslate'

module Redmine
  module Views
    module Builders
      class Structure < BlankSlate
        attr_accessor :request, :response

        def initialize(request, response)
          @struct = [{}]
          self.request = request
          self.response = response
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
