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

    class PlanningElementsController < PlanningElementsController

      include ::Api::V2::ApiController

      def index
        optimize_planning_elements_for_less_db_queries

        respond_to do |format|
          format.api
        end
      end

      def create
        @planning_element = @planning_elements.new(permitted_params.planning_element)
        successfully_created = @planning_element.save

        respond_to do |format|

          format.api do
            if successfully_created
              redirect_url = api_v2_project_planning_element_url(
                @project, @planning_element,
                # TODO this probably should be (params[:format] ||'xml'), however, client code currently anticipates xml responses.
                :format => 'xml'
              )
              see_other(redirect_url)
            else
              render_validation_errors(@planning_element)
            end
          end
        end
      end

      def show
        @planning_element = @project.planning_elements.find(params[:id])

        respond_to do |format|
          format.api
        end
      end

      def update
        @planning_element = @planning_elements.find(params[:id])
        @planning_element.attributes = permitted_params.planning_element

        successfully_updated = @planning_element.save

        respond_to do |format|
          format.api do
            if successfully_updated
              no_content
            else
              render_validation_errors(@planning_element)
            end
          end
        end
      end

      def list
        options = {:order => 'id'}

        projects = Project.visible.select do |project|
          User.current.allowed_to?(:view_planning_elements, project)
        end

        if params[:ids]
          ids = params[:ids].split(/,/).map(&:strip).select { |s| s =~ /^\d*$/ }.map(&:to_i).sort
          project_ids = projects.map(&:id).sort
          options[:conditions] = ["id IN (?) AND project_id IN (?)", ids, project_ids]
        end

        @planning_elements = PlanningElement.all(options)

        respond_to do |format|
          format.api { render :action => :index }
        end
      end

      def destroy
        @planning_element = @project.planning_elements.find(params[:id])
        @planning_element.destroy

        respond_to do |format|
          format.api
        end
      end
    end
  end
end
