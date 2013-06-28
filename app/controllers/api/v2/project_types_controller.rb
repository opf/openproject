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
  module V2

    class ProjectTypesController < ProjectTypesController

      include ::Api::V2::ApiController
      paginate_model ProjectType

      def index
        @project_types = ProjectType.all
        respond_to do |format|
          format.api
        end
      end

      def show
        @project_type = ProjectType.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end
