

module Api
  module V3

    class WorkPackagesController < ApplicationController
      unloadable

      include PaginationHelper
      include QueriesHelper
      include ::Api::V3::ApiController
      include ExtendedHTTP

      before_filter :authorize_and_setup_project
      before_filter :assign_planning_elements

      def index
        # the data for the index is already produced in the assign_planning_elements
        respond_to do |format|
          format.api
        end
      end

      private

      def authorize_and_setup_project
        find_project_by_project_id         unless performed?
        authorize                          unless performed?
      end

      def assign_planning_elements
        @work_packages = current_work_packages(@project) unless performed?
      end

      def current_work_packages(projects)
        query = retrieve_query

        results = query.results(:include => [:assigned_to, :type, :priority, :category, :fixed_version])
        work_packages = results.work_packages
                               .page(page_param)
                               .per_page(per_page_param)
                               .changed_since(@since)
                               .all

        set_planning_elements_meta(query, results, work_packages)

        work_packages
      end

      # TODO: This needs to assign the meta data:
      #       project_identifier
      #       query
      #       work_package_count_by_group
      #       sort_criteria
      #       sums
      #       group_sums
      #       page
      #       per_page
      #       per_page_options
      #       total_entries
      # Most of which can be lifted from work_packages_controller hopefully as long as the query is set up in the same way
      def set_planning_elements_meta(query, results, work_packages)
        @display_meta = true
        @columns = if params[:c]
                     params[:c].map {|c| c.to_sym }
                   else
                     [:id, :start_date] # TODO RS: Get defaults from somewhere sensible
                   end

        @work_packages_meta = {
          work_package_count_by_group:  results.work_package_count_by_group,
          sums:                         query.columns.map { |column| results.total_sum_of(column) },
          group_sums:                   query.group_by_column && query.columns.map { |column| results.grouped_sums(column) },
          page:                         page_param,
          per_page:                     per_page_param,
          per_page_options:             Setting.per_page_options_array,
          total_entries:                work_packages.total_entries
        }
      end

      # TODO RS: Taken from work_packages_controller, not dry - move to application controller.
      def per_page_param
        case params[:format]
        when 'csv', 'pdf'
          Setting.work_packages_export_limit.to_i
        when 'atom'
          Setting.feeds_limit.to_i
        else
          super
        end
      end
    end
  end
end