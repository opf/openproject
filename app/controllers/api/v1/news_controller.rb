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

module Api
  module V1

    class NewsController < NewsController

      include ::Api::V1::ApiController

      def index
        scope = @project ? @project.news.visible : News.visible

        @newss = scope.includes(:author, :project)
                      .order("#{News.table_name}.created_on DESC")
                      .page(page_param)
                      .per_page(per_page_param)

        respond_to do |format|
          format.api
        end
      end

    end
  end
end
