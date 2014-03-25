

module Api
  module V3

    class WorkPackagesController < ApplicationController
      unloadable

      DEFAULT_SORT_ORDER = ['parent', 'desc']

      include ApiController
      include Concerns::ColumnData

      include PaginationHelper
      include QueriesHelper
      include SortHelper
      include ExtendedHTTP


      # before_filter :authorize # TODO specify authorization
      before_filter :authorize_request, only: [:column_data]

      before_filter :find_optional_project, only: [:index]

      before_filter :retrieve_query, only: [:index]
      before_filter :assign_work_packages, only: [:index]

      def index
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        # the data for the index is already produced in the assign_work_packages
        respond_to do |format|
          format.api
        end
      end

      def column_data
        raise 'API Error: No IDs' unless params[:ids]
        raise 'API Error: No column names' unless params[:column_names]

        column_names = params[:column_names]
        ids = params[:ids].map(&:to_i)
        work_packages = Array.wrap(WorkPackage.visible.find(*ids)).sort {|a,b| ids.index(a.id) <=> ids.index(b.id)}

        @columns_data = fetch_columns_data(column_names, work_packages)
      end

      def column_sums
        raise 'API Error' unless params[:column_names]

        column_names = params[:column_names]
        project = Project.find_visible(current_user, params[:project_id])
        work_packages = project.work_packages

        @column_sums = column_names.map do |column_name|
          fetch_column_data(column_name, work_packages).map{|c| c.nil? ? 0 : c}.compact.sum if column_should_be_summed_up?(column_name)
        end
      end

      private

      def authorize_request
        # TODO: need to give this action a global role i think. tried making load_column_data role in reminde.rb
        #       but couldn't get it working.
        # authorize_global unless performed?
      end

      def assign_work_packages
        @work_packages = current_work_packages(@project) unless performed?
      end

      def current_work_packages(projects)
        results = @query.results(:include => [:assigned_to, :type, :priority, :category, :fixed_version])
        work_packages = results.work_packages
                               .page(page_param)
                               .per_page(per_page_param)
                               .changed_since(@since)
                               .all

        set_work_packages_meta_data(@query, results, work_packages)

        work_packages
      end

      def set_work_packages_meta_data(query, results, work_packages)
        @display_meta = true
        @columns = query.columns.map &:name

        @work_packages_meta_data = {
          query:                        query,
          columns:                      get_columns_for_json(query.columns),
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

      def fetch_columns_data(column_names, work_packages)
        column_names.map do |column_name|
          fetch_column_data(column_name, work_packages)
        end
      end

      def fetch_column_data(column_name, work_packages)
        if column_name =~ /cf_(.*)/
          custom_field = CustomField.find($1)
          work_packages.map do |work_package|
            custom_value = work_package.custom_values.find_by_custom_field_id($1)
            custom_field.cast_value custom_value.try(:value)
          end
        else
          work_packages.map do |work_package|
            # Note: Doing as_json here because if we just take the value.attributes then we can't get any methods later.
            #       Name and subject are the default properties that the front end currently looks for to summarize an object.
            value = work_package.send(column_name)
            value.is_a?(ActiveRecord::Base) ? value.as_json( only: "id", methods: [:name, :subject] ) : value
          end
        end
      end

      def column_should_be_summed_up?(column_name)
        # see ::Query::Sums mix in
        column_is_numeric?(column_name) && Setting.work_package_list_summable_columns.include?(column_name.to_s)
      end

      def column_is_numeric?(column_name)
        # TODO RS: We want to leave out ids even though they are numeric
        [:int, :float].include? column_type(column_name)
      end

      def column_type(column_name)
        if column_name =~ /cf_(.*)/
          CustomField.find($1).field_format.to_sym
        else
          column = WorkPackage.columns_hash[column_name]
          column.nil? ? :none : column.type
        end
      end
    end
  end
end
