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

    class ProjectAssociationsController < ProjectAssociationsController

      include ::Api::V2::ApiController

      respond_to :api

      def index
        @project_associations = @project.project_associations.visible

        respond_with(@project_associations)
      end

      def available_projects
        available_projects = @project.associated_project_candidates

        @elements = Project.project_level_list(Project.visible)
        @disabled = Project.visible - available_projects

        respond_with(@elements, @disabled)
      end

      def show
        @project_association = @project.project_associations.find(params[:id])
        check_visibility

        respond_with(@project_associations)
      end
    end

  end
end
