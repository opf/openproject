#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Query < ApplicationRecord
  include Timelines
  include Timestamps
  include Highlighting
  include ManualSorting
  include Queries::Filters::AvailableFilters

  belongs_to :project
  belongs_to :user
  has_many :views,
           dependent: :destroy
  has_many :ical_token_query_assignments
  has_many :ical_tokens,
           through: :ical_token_query_assignments,
           class_name: 'Token::ICal'
  # no `dependent: :destroy` as the ical_tokens are destroyed in the following before_destroy callback
  # dependent: :destroy is not possible as this would only delete the ical_token_query_assignments
  before_destroy :destroy_ical_tokens

  serialize :filters, coder: Queries::WorkPackages::FilterSerializer
  serialize :column_names, type: Array
  serialize :sort_criteria, type: Array

  validates :include_subprojects,
            inclusion: [true, false]

  validate :validate_work_package_filters
  validate :validate_columns
  validate :validate_sort_criteria
  validate :validate_group_by
  validate :validate_show_hierarchies
  validate :validate_timestamps

  include Scopes::Scoped
  scopes :visible,
         :having_views

  scope(:global, -> { where(project_id: nil) })

  def self.new_default(attributes = nil)
    new(attributes).tap do |query|
      query.add_default_filter
      query.set_default_sort
      query.show_hierarchies = true
      query.include_subprojects = Setting.display_subprojects_work_packages?
    end
  end

  ##
  # Ensure the filters receive
  # the query context as this appears to be lost
  # whenever the field is reloaded from the serialized value
  def filters
    super.tap do |filters|
      filters.each do |filter|
        filter.context = self
      end
    end
  end

  def set_default_sort
    return if sort_criteria.any?

    self.sort_criteria = [%w[id asc]]
  end

  def context
    self
  end

  def to_s
    name
  end

  def add_default_filter
    return if filters.present?

    add_filter('status_id', 'o', [''])
  end

  def validate_work_package_filters
    filters.each do |filter|
      unless filter.valid?
        errors.add :base, filter.error_messages
      end
    end
  end

  def validate_columns
    available_names = displayable_columns.map(&:name).map(&:to_sym)

    (column_names - available_names).each do |name|
      errors.add :column_names,
                 :invalid,
                 value: name
    end
  end

  def validate_sort_criteria
    available_criteria = sortable_columns.map(&:name).map(&:to_s)

    sort_criteria.each do |name, _dir|
      unless available_criteria.include? name.to_s
        errors.add :sort_criteria, :invalid, value: name
      end
    end
  end

  def validate_group_by
    unless group_by.blank? || groupable_columns.map(&:name).map(&:to_s).include?(group_by.to_s)
      errors.add :group_by, :invalid, value: group_by
    end
  end

  def validate_show_hierarchies
    if show_hierarchies && group_by.present?
      errors.add :show_hierarchies, :group_by_hierarchies_exclusive, group_by:
    end
  end

  def validate_timestamps
    forbidden_timestamps = timestamps - allowed_timestamps
    if forbidden_timestamps.any?
      errors.add :timestamps, :forbidden, values: forbidden_timestamps.join(", ")
    end
  end

  def hidden
    views.empty?
  end

  # Try to fix an invalid query
  #
  # Fixes:
  # * filters:
  #     Reduces the filter's values to those that are valid.
  #     If the filter remains invalid, it is removed.
  # * group_by:
  #     Removes the group by if it is invalid
  # * sort_criteria
  #     Removes all invalid criteria
  # * columns
  #     Removes all invalid columns
  #
  # If the query has been valid or if the error
  # is not one of the addressed, the query is unchanged.
  def valid_subset!
    valid_filter_subset!
    valid_group_by_subset!
    valid_sort_criteria_subset!
    valid_column_subset!
    valid_timestamps_subset!
  end

  def add_filter(field, operator, values)
    filter = filter_for(field)

    filter.operator = operator
    filter.values = values

    filters << filter
  end

  def filter_for(field)
    filter = (filters || []).detect { |f| f.field.to_s == field.to_s } || super(field)

    filter.context = self

    filter
  end

  # Removes the filter with the given name
  # from the query without persisting the change.
  #
  # @param [String] name the filter to remove
  def remove_filter(name)
    filters.delete_if { |f| f.field.to_s == name.to_s }
  end

  def normalized_name
    name.parameterize.underscore
  end

  def available_columns
    if @available_columns &&
       (@available_columns_project == (project&.cache_key || 0))
      return @available_columns
    end

    @available_columns_project = project&.cache_key || 0
    @available_columns = ::Query.available_columns(project)
  end

  def self.available_columns(project = nil)
    Queries::Register
      .selects[self]
      .map { |col| col.instances(project) }
      .flatten
  end

  def self.displayable_columns
    available_columns.select(&:displayable?)
  end

  def self.groupable_columns
    available_columns.select(&:groupable)
  end

  def self.sortable_columns
    available_columns.select(&:sortable)
  end

  def displayable_columns
    available_columns.select(&:displayable?)
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select(&:groupable)
  end

  # Returns an array of columns that can be used to sort the results
  def sortable_columns
    available_columns.select(&:sortable)
  end

  # Returns a Hash of sql columns for sorting by column
  def sortable_key_by_column_name
    column_sortability = sortable_columns.inject({}) do |h, column|
      h[column.name.to_s] = column.sortable
      h
    end

    { 'id' => "#{WorkPackage.table_name}.id" }
      .merge(column_sortability)
  end

  def summed_up_columns
    available_columns.select(&:summable?)
  end

  def columns
    column_list = if has_default_columns?
                    column_list = Setting.work_package_list_default_columns.dup.map(&:to_sym)
                    # Adds the project column by default for cross-project lists
                    column_list += [:project] if project.nil? && column_list.exclude?(:project)
                    column_list
                  else
                    column_names
                  end

    # preserve the order
    column_list.filter_map { |name| displayable_columns.find { |col| col.name == name.to_sym } }
  end

  def column_names=(names)
    col_names = Array(names)
                .compact_blank
                .map(&:to_sym)

    # Set column_names to blank/nil if it is equal to the default columns
    if col_names.map(&:to_s) == Setting.work_package_list_default_columns
      col_names.clear
    end

    write_attribute(:column_names, col_names)
  end

  def has_column?(column)
    column_names&.include?(column.name)
  end

  def has_default_columns?
    column_names.empty?
  end

  def sort_criteria=(arg)
    if arg.is_a?(Hash)
      arg = arg.keys.sort.map { |k| arg[k] }
    end
    c = arg.reject { |k, _o| k.to_s.blank? }.slice(0, 3).map { |k, o| [k.to_s, o == 'desc' ? o : 'asc'] }
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    (read_attribute(:sort_criteria) || []).tap do |criteria|
      criteria.map! do |attr, direction|
        attr = 'id' if attr == 'parent'
        [attr, direction]
      end
    end
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end

  def sort_criteria_columns
    sort_criteria
      .map do |attribute, direction|
        attribute = attribute.to_sym

        [sort_criteria_column(attribute), direction]
      end
  end

  def sort_criteria_column(attribute)
    sortable_columns
      .detect { |candidate| candidate.name == attribute }
  end

  def ordered?
    sort_criteria.any?
  end

  # Returns true if the query is a grouped query
  def grouped?
    !group_by_column.nil?
  end

  def display_sums?
    display_sums
  end

  def group_by_column
    groupable_columns.detect { |c| c.groupable && c.name.to_s == group_by }
  end

  def group_by_statement
    group_by_column.try(:groupable)
  end

  def statement
    return '1=0' unless valid?

    statement_filters
      .map { |filter| "(#{filter.where})" }
      .compact_blank
      .join(' AND ')
  end

  # Returns the result set
  def results
    Results.new(self)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def work_package_journals(options = {})
    Journal.includes(:user)
           .where(journable_type: WorkPackage.to_s)
           .joins('INNER JOIN work_packages ON work_packages.id = journals.journable_id')
           .joins('INNER JOIN projects ON work_packages.project_id = projects.id')
           .joins('INNER JOIN users AS authors ON work_packages.author_id = authors.id')
           .joins('INNER JOIN types ON work_packages.type_id = types.id')
           .joins('INNER JOIN statuses ON work_packages.status_id = statuses.id')
           .order(options[:order])
           .limit(options[:limit])
           .offset(options[:offset])
           .references(:users)
           .merge(WorkPackage.visible)
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def project_limiting_filter
    return if project_filter_set?

    subproject_filter = Queries::WorkPackages::Filter::SubprojectFilter.create!
    subproject_filter.context = self

    subproject_filter.operator = if include_subprojects?
                                   '*'
                                 else
                                   '!*'
                                 end
    subproject_filter
  end

  private

  ##
  # Determine whether there are explicit filters
  # on whether work packages from
  # * subprojects
  # * other projects
  # are used.
  def project_filter_set?
    filters.any? do |filter|
      filter.is_a?(::Queries::WorkPackages::Filter::SubprojectFilter) ||
        filter.is_a?(::Queries::WorkPackages::Filter::ProjectFilter)
    end
  end

  def for_all?
    @for_all ||= project.nil?
  end

  def statement_filters
    if project
      filters + [project_limiting_filter].compact
    else
      filters
    end
  end

  def allowed_timestamps
    Timestamp.allowed(timestamps)
  end

  def valid_filter_subset!
    filters.each(&:valid_values!).select! do |filter|
      filter.available? && filter.valid?
    end
  end

  def valid_group_by_subset!
    unless groupable_columns.map(&:name).map(&:to_s).include?(group_by.to_s)
      self.group_by = nil
    end
  end

  def valid_sort_criteria_subset!
    available_criteria = sortable_columns.map(&:name).map(&:to_s)

    sort_criteria.select! do |criteria|
      available_criteria.include? criteria.first.to_s
    end
  end

  def valid_column_subset!
    available_names = displayable_columns.map(&:name).map(&:to_sym)

    self.column_names &= available_names
  end

  def valid_timestamps_subset!
    self.timestamps &= allowed_timestamps
  end

  # dependent::destroy does not work for has_many :through associations
  # only the ical_token_query_assignments would be destroyed
  def destroy_ical_tokens
    ical_tokens.each(&:destroy)
  end
end
