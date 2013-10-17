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
        optimize_planning_elements_for_less_db_queries
        rewire_ancestors

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
        @planning_element = @project.work_packages.find(params[:id])

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

      # Filters
      def find_all_projects_by_project_id
        if params[:project_id] !~ /,/
          find_project_by_project_id         unless performed?
          authorize                          unless performed?
          assign_planning_elements(@project) unless performed?
        else
          # find_project_by_project_id
          ids, identifiers = params[:project_id].split(/,/).map(&:strip).partition { |s| s =~ /^\d*$/ }
          ids = ids.map(&:to_i).sort
          identifiers = identifiers.sort

          @projects = []
          @projects |= Project.all(:conditions => {:id => ids}) unless ids.empty?
          @projects |= Project.all(:conditions => {:identifier => identifiers}) unless identifiers.empty?

          if (@projects.map(&:id) & ids).size != ids.size ||
             (@projects.map(&:identifier) & identifiers).size != identifiers.size
            # => not all projects could be found
            render_404
            return
          end

          # authorize
          # Ignoring projects, where user has no view_work_packages permission.
          permission = params[:controller].sub api_version, ''
          @projects = @projects.select do |project|
            User.current.allowed_to?({:controller => permission,
                                      :action     => params[:action]},
                                      project)
          end

          if @projects.blank?
            @planning_elements = []
            return
          end

          assign_planning_elements(@projects)
        end
      end

      # is called as a before filter and as a method
      def assign_planning_elements(projects = (@projects || [@project]))

        @planning_elements = if params[:at_time]
                               historical_work_packages(projects)
                             else
                               current_work_packages(projects)
                             end
      end

      def current_work_packages(projects)
        work_packages = WorkPackage.for_projects(projects).without_deleted

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

      def optimize_planning_elements_for_less_db_queries
        # triggering full load to avoid separate queries for count or related models
        # historical packages are already loaded correctly and only need to be optimised, so they do not need to fetched again, only optimised
        @planning_elements = @planning_elements.all(:include => [:type, :status, :project, :responsible]) unless @planning_elements.class == Array

        # Replacing association proxies with already loaded instances to avoid
        # further db calls.
        #
        # This assumes, that all planning elements within a project where loaded
        # and that parent-child relations may only occur within a project.
        #
        # It is also dependent on implementation details of ActiveRecord::Base,
        # so it might break in later versions of Rails.
        #
        # See association_instance_get/_set in ActiveRecord::Associations

        ids_hash      = @planning_elements.inject({}) { |h, pe| h[pe.id] = pe; h }
        children_hash = Hash.new { |h,k| h[k] = [] }

        parent_refl, children_refl = [:parent, :children].map{|assoc| WorkPackage.reflect_on_association(assoc)}

        associations = {
          :belongs_to => ActiveRecord::Associations::BelongsToAssociation,
          :has_many => ActiveRecord::Associations::HasManyAssociation
        }

        # 'caching' already loaded parent and children associations
        @planning_elements.each do |pe|
          children_hash[pe.parent_id] << pe

          parent = nil
          if ids_hash.has_key? pe.parent_id
            parent = associations[parent_refl.macro].new(pe, parent_refl)
            parent.target = ids_hash[pe.parent_id]
          end
          pe.send(:association_instance_set, :parent, parent)

          children = associations[children_refl.macro].new(pe, children_refl)
          children.target = children_hash[pe.id]
          pe.send(:association_instance_set, :children, children)
        end
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
          # remove all children, that are not present in the filtered set
          pe.children = pe.children.select {|child| filtered_ids.include? child.id} unless pe.children.empty?
          # re-wire the parent of this pe to the first ancestor found in the filtered set
          # re-wiring is only needed, when there is actually a parent, and the parent has been filtered out
          if pe.parent_id && !filtered_ids.include?(pe.parent_id)
            ancestors = @planning_elements.select{|candidate| candidate.lft < pe.lft && candidate.rgt > pe.rgt }
            # the greatest lower boundary is the first ancestor not filtered
            pe.parent = ancestors.sort_by{|ancestor| ancestor.lft }.last
          end

        end
      end
    end
  end
end
