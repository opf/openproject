#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
      helper :timelines, :planning_elements

      include ::Api::V2::ApiController
      include ::Api::V2::Concerns::MultipleProjects
      include ExtendedHTTP

      before_action :find_project_by_project_id,
                    :authorize, except: [:index]
      before_action :parse_changed_since, only: [:index]

      # Attention: find_all_projects_by_project_id needs to mimic all of the above
      #            before filters !!!
      before_action :find_all_projects_by_project_id, only: :index

      helper :timelines

      accept_key_auth :index, :create, :show, :update, :destroy

      def index
        # the data for the index is already produced in the assign_planning_elements
        respond_to do |format|
          format.api
        end
      end

      def create
        @planning_element = @project.work_packages.build
        attributes = permitted_params.planning_element(project: @project).except :note

        @planning_element.update_attributes(lookup_custom_options(attributes))
        @planning_element.attach_files(params[:attachments])

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
                format: 'xml'
              )
              see_other(redirect_url)
            else
              render_validation_errors(@planning_element)
            end
          end
        end
      end

      def show
        @planning_element = @project.work_packages
                                    .includes(custom_values: :custom_field)
                                    .find(params[:id])

        respond_to do |format|
          format.api
        end
      end

      def update
        @planning_element = WorkPackage.find(params[:id])
        attributes = permitted_params.planning_element(project: @project).except :note
        @planning_element.attributes = lookup_custom_options attributes
        @planning_element.add_journal(User.current, permitted_params.planning_element(project: @project)[:note])

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
        @planning_element = WorkPackage.find(params[:id])
        @planning_element.destroy

        respond_to do |format|
          format.api
        end
      end

      protected

      def lookup_custom_options(attributes)
        return attributes unless attributes.include?("custom_fields")

        custom_fields = attributes["custom_fields"].map do |custom_field|
          if CustomField.where(id: custom_field["id"], field_format: "list").exists?
            value = custom_field["value"]
            custom_option_id = begin
              Integer(value)
            rescue
              lookup_custom_option(custom_field)
            end

            custom_field.merge value: custom_option_id || value
          else
            custom_field
          end
        end

        attributes.merge custom_fields: custom_fields
      end

      def lookup_custom_option(custom_field_attributes)
        custom_field_id = custom_field_attributes["id"]
        value = custom_field_attributes["value"]

        CustomOption.where(custom_field_id: custom_field_id, value: value).pluck(:id)
      end

      def load_multiple_projects(ids, identifiers)
        @projects = []
        @projects |= Project.where(id: ids) unless ids.empty?
        @projects |= Project.where(identifier: identifiers) unless identifiers.empty?
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
        if !params[:project_id] and params[:ids]
          # WTF. Why do we completely skip rewiring in this case and always provide parent_ids?
          # This is totally inconistent.
          identifiers = params[:ids].split(/,/).map(&:strip)
          @planning_elements = WorkPackage.visible(User.current).where(id: identifiers)
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

          # Allow disabling rewiring - this exposes parent IDs of work packages invisible
          # to the user.
          # When requesting single work packages via IDs, the rewiring fails as it assumes
          # that all visible work packages are loaded, which they might not be. For a work
          # package with a parent visible to the user, but not included in the requested IDs,
          # the parent_id would thus be nil.
          # Disabling rewiring allows fetching work packages with their parent_ids
          # even when the parents are not included in the list of requested work packages.
          rewire_ancestors unless params[:rewire_parents] == 'false'
        end
      end

      Struct.new('WorkPackage', *[WorkPackage.column_names.map(&:to_sym), :custom_values, :child_ids].flatten)
      Struct.new('CustomValue', :typed_value, *CustomValue.column_names.map(&:to_sym))

      def convert_wp_to_struct(work_package)
        struct = Struct::WorkPackage.new

        fill_struct_with_attributes(struct, work_package)
      end

      def convert_custom_value_to_struct(custom_value)
        struct = Struct::CustomValue.new

        fill_struct_with_attributes(struct, custom_value)
      end

      def fill_struct_with_attributes(struct, model)
        model.attributes.each do |attribute, value|
          struct.send(:"#{attribute}=", value)
        end

        if model.is_a? CustomValue
          struct.value = value_for_frontend model
        end

        struct
      end

      ##
      # Returns the value of this custom field as needed by the APIv2.
      # For instance it expects the raw value for user custom fields to
      # use it (the ID) to lookup the user.
      #
      # On the other hand for list custom fields it can't do the lookup
      # (there is no custom options API) and besides it shouldn't.
      def value_for_frontend(custom_value)
        if custom_value.custom_field.list?
          custom_value.typed_value
        else
          custom_value.value
        end
      end

      def convert_wp_object_to_struct(model)
        result = convert_wp_to_struct(model)
        result.custom_values = custom_values_for(model)

        result
      end

      def custom_values_for(model)
        model
          .custom_values.select { |cv| cv.value != '' }
          .map { |custom_value| convert_custom_value_to_struct(custom_value) }
      end

      def convert_to_struct(collection)
        collection.map do |model|
          convert_wp_object_to_struct(model)
        end
      end

      def planning_comparison?
        params[:at_time].present?
      end

      def timeline_to_project(timeline_id)
        if timeline_id
          project = Timeline.find_by(id: params[:timeline]).project
          user_has_access = User.current.allowed_to?({ controller: 'planning_elements',
                                                       action:     'index' },
                                                     project)
          if user_has_access
            return project
          end
        end
      end

      def current_work_packages(projects)
        work_packages = WorkPackage
                        .for_projects(projects)
                        .changed_since(@since)
                        .includes(:status, :project, :type, custom_values: :custom_field)
                        .references(:projects)

        wp_ids = parse_work_package_ids
        work_packages = work_packages.where(id: wp_ids) if wp_ids

        if params[:f]
          work_packages = work_packages.merge(filtered_work_package_scope(params))
        end

        work_packages
      end

      def historical_work_packages(projects)
        at_time = Time.at(params[:at_time].to_i).to_datetime
        filter = params[:f] ? { f: params[:f], op: params[:op], v: params[:v] } : {}
        historical = PlanningComparisonService.compare(projects, at_time, filter)
      end

      # Helpers
      helper_method :include_journals?

      def include_journals?
        # .tap and the following block here were useless as the block's return value is ignored.
        # Keeping this code to show its original intention, but not fixing it to not
        # break things for clients that might not properly use the parameter.
        params[:include]  # .tap { |i| i.present? && i.include?("journals") }
      end

      # Actual protected methods
      def render_errors(errors)
        options = { status: :bad_request, layout: false }
        options.merge!(case params[:format]
                       when 'xml';  { xml: errors }
                       when 'json'; { json: { 'errors' => errors } }
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
            ancestors = @planning_elements.select { |candidate| candidate.lft < pe.lft && candidate.rgt > pe.rgt && candidate.root_id == pe.root_id }
            # the greatest lower boundary is the first ancestor not filtered
            pe.parent_id = ancestors.empty? ? nil : ancestors.sort_by(&:lft).last.id
          end
        end

        # we explicitly need to re-construct the array of child-ids
        @planning_elements.each do |pe|
          pe.child_ids = @planning_elements.select { |child| child.parent_id == pe.id }
            .map(&:id)
        end
      end

      private

      def parse_changed_since
        @since = Time.at(Float(params[:changed_since] || 0).to_i) rescue render_400
      end

      def parse_work_package_ids
        params[:ids] ? params[:ids].split(',') : nil
      end

      def filtered_work_package_scope(params)
        # we need a project to make project-specific custom fields work
        project = timeline_to_project(params[:timeline])
        query = Query.new(project: project, name: '_')

        query.add_filters(params[:f], params[:op], params[:v])

        # if we do not remove the project, the filter will only add wps from this project
        # but as the filters still need the project (e.g. to determine whether they are valid),
        # we need to duplicate the query and assign it to the filters
        filter_query = query.dup
        query.filters.each do |filter|
          filter.context = filter_query
        end
        query.project = nil

        WorkPackage.with_query query
      end
    end
  end
end
