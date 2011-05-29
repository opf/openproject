#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
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
      def self.for(format, &block)
        builder = case format
          when 'xml',  :xml;  Builders::Xml.new
          when 'json', :json; Builders::Json.new
          else; raise "No builder for format #{format}"
        end
        if block
          block.call(builder)
        else
          builder
        end
      end
    end
  end
end
