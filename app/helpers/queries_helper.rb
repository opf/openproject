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

module QueriesHelper
  def operators_for_select(filter)
    # We do not support OnDate(Time) and BetweenDate(Time)
    # for rails based filters
    operators = filter
                .available_operators
                .reject do |o|
                  [Queries::Operators::OnDate,
                   Queries::Operators::OnDateTime,
                   Queries::Operators::BetweenDate,
                   Queries::Operators::BetweenDateTime].include?(o)
                end

    operators.map { |o| [o.human_name, o.to_sym] }
  end

  def entries_for_filter_select_sorted(query)
    [['', '']] +
      query.available_filters
           .reject { |filter| query.has_filter?(filter.name) }
           .map { |filter| [filter.human_name, filter.name] }
           .sort_by { |el| ActiveSupport::Inflector.transliterate(el[0]).downcase }
  end

  def column_locale(column)
    column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn) ? column.custom_field.name_locale : nil
  end

  def add_filter_from_params(query, filters: params)
    query.filters = []
    query.add_filters(
      fields_from_params(filters),
      operators_from_params(filters),
      values_from_params(filters)
    )
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    if params[:query_id].present?
      cond = 'project_id IS NULL'
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.where(cond).find(params[:query_id])
      @query.project = @project
      add_filter_from_params(@query) if params[:accept_empty_query_fields]
      session[:query] = { id: @query.id, project_id: @query.project_id }
      sort_clear
    else
      if api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = Query.new(name: '_')
        @query.project = @project
        if params[:fields] || params[:f]
          add_filter_from_params(@query)
        else
          @query.available_filters.map(&:name).each do |field|
            @query.add_short_filter(field, params[field]) if params[field]
          end
        end

        @query.group_by = group_by_from_params params
        @query.display_sums = params[:display_sums].present? && params[:display_sums] == 'true'
        @query.column_names = column_names_from_params params
        session[:query] = {
          project_id: @query.project_id,
          filters: Queries::FilterSerializer.dump(@query.filters),
          group_by: @query.group_by,
          display_sums: @query.display_sums,
          column_names: @query.column_names
        }
      else
        @query = Query.find_by(id: session[:query][:id]) if session[:query][:id]
        @query ||= Query.new(name: '_',
                             project: @project,
                             filters: Queries::FilterSerializer.load(session[:query][:filters]),
                             group_by: session[:query][:group_by],
                             display_sums: session[:query][:display_sums],
                             column_names: session[:query][:column_names])
        @query.project = @project
      end
    end

    @query
  end

  def retrieve_query_v3
    @query = if params[:query_id].present?
               Query.where(project: @project).find(params[:query_id])
             else
               Query.new_default(name: '_',
                                 project: @project)
             end

    ::API::V3::UpdateQueryFromV3ParamsService
      .new(@query, current_user)
      .call(params)

    @query
  end

  ##
  # Reads column names from the request parameters and converts them
  # from the frontend names to names recognized by the backend.
  # Examples:
  #   * assigned => assigned_to
  #   * customField1 => cf_1
  #
  # @param params [Hash] Request parameters
  # @return [Array] The column names read from the parameters or nil if none were given.
  def column_names_from_params(params)
    names = params[:c] || (params[:query] && params[:query][:column_names])

    names.map { |name| attribute_converter.to_ar_name name } if names
  end

  def visible_queries
    unless @visible_queries
      # Find project queries or global queries depending on @project.nil?
      @visible_queries = Query
                         .visible(to: User.current)
                         .where(project_id: @project)
                         .order('name ASC')
                         .select(:id, :name, :is_public, :project_id)
    end
    @visible_queries
  end

  module_function

  def group_by_from_params(params)
    params[:group_by] || params[:groupBy] || params[:g]
  end

  def fields_from_params(params)
    fix_field_array(params[:fields] || params[:f]).compact
  end

  def operators_from_params(params)
    fix_field_hash(params[:operators] || params[:op])
  end

  def values_from_params(params)
    fix_field_hash(params[:values] || params[:v])
  end

  def fix_field_hash(field_hash)
    return nil if field_hash.nil?

    names = field_hash.keys
    entries = names
              .zip(fix_field_array(names))
              .select { |_name, field| field.present? }
              .map { |name, field| [field, field_hash[name]] }

    Hash[entries]
  end

  ##
  # Maps given field names coming from the frontend to the actual names
  # as expected by the query. This works slightly different to what happens
  # in #column_names_from_params. For instance while they column name is
  # :type the expected field name is :type_id.
  #
  # Examples:
  #   * status => status_id
  #   * progresssDone => done_ratio
  #   * assigned => assigned_to
  #   * customField1 => cf_1
  #
  # @param query [Query] Query for which to get the correct field names.
  # @param field_names [Array] Field names as read from the params.
  # @return [Array] Returns a list of fixed field names. The list may contain nil values
  #                 for fields which could not be found.
  def fix_field_array(field_names)
    return [] if field_names.nil?

    field_names
      .map { |name| filter_converter.to_ar_name name, refer_to_ids: true }
  end

  def filter_converter
    API::Utilities::QueryFiltersNameConverter
  end

  def attribute_converter
    API::Utilities::WpPropertyNameConverter
  end
end
