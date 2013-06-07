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

require 'builder'

module Redmine
  module Views
    module Builders
      class Xml < ::Builder::XmlMarkup
        def initialize(request, response)
          super()
          instruct!
        end

        def output
          target!
        end

        def method_missing(sym, *args, &block)
          if args.size == 1 && args.first.kind_of?(::Time)
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
