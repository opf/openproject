#-- encoding: UTF-8
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
    class ApiTemplateHandler

      def self.call(template)
        # This will keep an api builder intact when calling partials
        %Q{
          if @api
            # inner template
            api = @api
            #{template.source}
          else
            # base template
            Redmine::Views::Builders.for(params[:format], request, response) do |api|
              @api ||= api
              #{template.source}
              self.output_buffer = api.output
            end
          end
        }
      end
    end
  end
end
