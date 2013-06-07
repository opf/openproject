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

module Redmine
  module Views
    module Builders
      def self.for(format, request, response, &block)
        builder = case format
          when 'xml',  :xml;  Builders::Xml.new(request, response)
          when 'json', :json; Builders::Json.new(request, response)
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
