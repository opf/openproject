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

    class PlanningElementTypesController < TypesController

      include ::Api::V2::ApiController

      extend Pagination::Controller
      paginate_model ::Api::V2::PlanningElementType

      before_filter {|controller| controller.find_optional_project_and_raise_error('types') }
      before_filter :check_project_exists

      def index
        @types = (@project.nil?) ? Type.all : @project.types

        respond_to do |format|
          format.api
        end
      end

      def show
        @type = (@project.nil?) ? Type.find(params[:id])
                                : @project.types.find(params[:id])

        respond_to do |format|
          format.api
        end
      end

      private

      def check_project_exists
        if params.has_key? :project_id && @project.nil?
          raise ActiveRecord::RecordNotFound
        end
      end
    end

  end
end
