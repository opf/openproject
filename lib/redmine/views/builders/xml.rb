#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
