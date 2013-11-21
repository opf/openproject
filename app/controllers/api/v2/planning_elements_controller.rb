#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module V2

    class PlanningElementsController < ApplicationController
      unloadable
      helper :timelines, :planning_elements

      include ::Api::V2::ApiController
      include ExtendedHTTP

      before_filter :find_project_by_project_id,
                    :authorize, :except => [:index]
      before_filter :assign_planning_elements, :except => [:index, :update, :create]

      # Attention: find_all_projects_by_project_id needs to mimic all of the above
      #            before filters !!!
      before_filter :find_all_projects_by_project_id, :only => :index

      helper :timelines

      accept_key_auth :index, :create, :show, :update, :destroy

      def index
        # the data for the index is already produced in the assign_planning_elements
        respond_to do |format|
          format.api
        end
      end

      def create
        @planning_element = planning_element_scope.new(permitted_params.planning_element)

        # The planning_element inherits from workpackage, which requires an author.
        # Using the current_user also satisfies this demand for API-calls
        @planning_element.author ||= current_user
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
        @planning_element = @project.work_packages.find params[:id],
          :include => [{:custom_values => [{:custom_field => :translations}]}]

        respond_to do |format|
          format.api
        end
      end

      def update
        @planning_element = planning_element_scope.find(params[:id])
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

      def destroy
        @planning_element = planning_element_scope.find(params[:id])
        @planning_element.destroy

        respond_to do |format|
          format.api
        end
      end

      protected

      def filter_authorized_projects
        # authorize
        # Ignoring projects, where user has no view_work_packages permission.
        permission = params[:controller].sub api_version, ''
        @projects = @projects.select do |project|
          User.current.allowed_to?({:controller => permission,
                                    :action     => params[:action]},
                                    project)
        end
      end

      def load_multiple_projects(ids, identifiers)
        @projects = []
        @projects |= Project.all(:conditions => {:id => ids}) unless ids.empty?
        @projects |= Project.all(:conditions => {:identifier => identifiers}) unless identifiers.empty?
      end

      def projects_contain_certain_ids_and_identifiers(ids, identifiers)
        (@projects.map(&:id) & ids).size == ids.size &&
        (@projects.map(&:identifier) & identifiers).size == identifiers.size
      end

      def find_single_project
        find_project_by_project_id         unless performed?
        authorize                          unless performed?
        assign_planning_elements(@project) unless performed?
      end

      def find_multiple_projects
        # find_project_by_project_id
        ids, identifiers = params[:project_id].split(/,/).map(&:strip).partition { |s| s =~ /\A\d*\z/ }
        ids = ids.map(&:to_i).sort
        identifiers = identifiers.sort

        load_multiple_projects(ids, identifiers)

        if !projects_contain_certain_ids_and_identifiers(ids, identifiers)
          # => not all projects could be found
          render_404
          return
        end

        filter_authorized_projects

        if @projects.blank?
          @planning_elements = []
          return
        end

        assign_planning_elements(@projects)
      end

      # Filters
      def find_all_projects_by_project_id
        if !params[:project_id] and params[:ids] then
          identifiers = params[:ids].split(/,/).map(&:strip)
          @planning_elements = WorkPackage.visible(User.current).find_all_by_id(identifiers)
        elsif params[:project_id] !~ /,/
          find_single_project
        else
          find_multiple_projects
        end
      end

      # is called as a before filter and as a method
      # The method optimises for speed and replaces the AR with structs, that make
      # sure that there are no callbacks to the db (producing nasty n+1 errors)
      def assign_planning_elements(projects = (@projects || [@project]))

        if planning_comparison?
          @planning_elements = convert_to_struct(historical_work_packages(projects))
        else
          @planning_elements = convert_to_struct(current_work_packages(projects))
          # only for current work_packages, the array of child-ids must be reconstructed
          # for historical packages, the re-wiring is not needed
          rewire_ancestors
        end

      end

      def convert_to_struct(collection)
        collection.map{|model| OpenStruct.new(model.attributes)}
      end

      def planning_comparison?
        params[:at_time].present?
      end

      def current_work_packages(projects)
        work_packages = WorkPackage.for_projects(projects).without_deleted
                                   .includes(:status, :project, :type)

        if params[:f]
          query = Query.new
          query.add_filters(params[:f], params[:op], params[:v])
          work_packages = work_packages.with_query query
        end

        work_packages
      end

      def historical_work_packages(projects)
        at_time = Time.at(params[:at_time].to_i).to_datetime
        filter = params[:f] ? {f: params[:f], op: params[:op], v: params[:v]}: {}
        historical = PlanningComparisonService.compare(projects, at_time, filter)
      end

      # remove this and replace by calls it with calls
      # to assign_planning_elements once WorkPackages can be created
      def planning_element_scope
        @project.work_packages.without_deleted
      end

      # Helpers
      helper_method :include_journals?

      def include_journals?
        params[:include].tap { |i| i.present? && i.include?("journals") }
      end

      # Actual protected methods
      def render_errors(errors)
        options = {:status => :bad_request, :layout => false}
        options.merge!(case params[:format]
          when 'xml';  {:xml => errors}
          when 'json'; {:json => {'errors' => errors}}
          else
            raise "Unknown format #{params[:format]} in #render_validation_errors"
          end
        )
        render options
      end

      # Filtering work_packages can destroy the parent-child-relationships
      # of work_packages. If parents are removed, the relationships need
      # to be rewired to the first ancestor in the ancestor-chain.
      #
      # Before Filtering:
      # A -> B -> C
      # After Filtering:
      # A -> C
      #
      # to see the respective cases that need to be handled properly by this rewiring,
      # @see features/planning_elements/filter.feature
      def rewire_ancestors

        filtered_ids = @planning_elements.map(&:id)

        @planning_elements.each do |pe|

          # re-wire the parent of this pe to the first ancestor found in the filtered set
          # re-wiring is only needed, when there is actually a parent, and the parent has been filtered out
          if pe.parent_id && !filtered_ids.include?(pe.parent_id)
            ancestors = @planning_elements.select{|candidate| candidate.lft < pe.lft && candidate.rgt > pe.rgt }
            # the greatest lower boundary is the first ancestor not filtered
            pe.parent_id = ancestors.empty? ? nil : ancestors.sort_by{|ancestor| ancestor.lft }.last.id
          end
        end

        # we explicitly need to re-construct the array of child-ids
        @planning_elements.each do |pe|
          pe.child_ids = @planning_elements.select {|child| child.parent_id == pe.id}
                                              .map(&:id)
        end


      end
    end
  end
end
