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

class Query < ActiveRecord::Base
  include Queries::AvailableFilters

  belongs_to :project
  belongs_to :user
  has_one :query_menu_item, -> { order('name') },
          class_name: 'MenuItems::QueryMenuItem',
          dependent: :delete, foreign_key: 'navigatable_id'
  serialize :filters, Queries::WorkPackages::FilterSerializer
  serialize :column_names, Array
  serialize :sort_criteria, Array

  validates :name, presence: true
  validates_length_of :name, maximum: 255

  validate :validate_work_package_filters
  validate :validate_columns
  validate :validate_sort_criteria
  validate :validate_group_by
  validate :validate_show_hierarchies

  scope(:visible, ->(to:) do
    # User can see public queries and his own queries
    scope = where(is_public: true)

    if to.logged?
      scope.or(where(user_id: to.id))
    else
      scope
    end
  end)

  scope(:global, -> { where(project_id: nil) })

  # WARNING: sortable should not contain a column called id (except for the
  # work_packages.id column). Otherwise naming collisions can happen when AR
  # optimizes a query into two separate DB queries (e.g. when joining tables).
  # The first query is employed to fetch all ids which are used as filters in
  # the second query. The columns mentioned in sortable are used for the first
  # query.  If such a statement selects from two coluns named <table name>.id
  # the second one is taken to get the ids of the work packages.
  @@available_columns = [
    QueryColumn.new(:id,
                    sortable: "#{WorkPackage.table_name}.id",
                    groupable: false),
    QueryColumn.new(:project,
                    sortable: "#{Project.table_name}.name",
                    groupable: true),
    QueryColumn.new(:subject,
                    sortable: "#{WorkPackage.table_name}.subject"),
    QueryColumn.new(:type,
                    sortable: "#{::Type.table_name}.position",
                    groupable: true),
    QueryColumn.new(:parent,
                    sortable: ["#{WorkPackage.table_name}.root_id ASC",
                               "#{WorkPackage.table_name}.lft ASC"],
                    default_order: 'asc'),
    QueryColumn.new(:status,
                    sortable: "#{Status.table_name}.position",
                    groupable: true),
    QueryColumn.new(:priority,
                    sortable: "#{IssuePriority.table_name}.position",
                    default_order: 'desc',
                    groupable: true),
    QueryColumn.new(:author,
                    sortable: ["#{User.table_name}.lastname",
                               "#{User.table_name}.firstname",
                               "#{WorkPackage.table_name}.author_id"],
                    groupable: true),
    QueryColumn.new(:assigned_to,
                    sortable: ["#{User.table_name}.lastname",
                               "#{User.table_name}.firstname",
                               "#{WorkPackage.table_name}.assigned_to_id"],
                    groupable: true),
    QueryColumn.new(:responsible,
                    sortable: ["#{User.table_name}.lastname",
                               "#{User.table_name}.firstname",
                               "#{WorkPackage.table_name}.responsible_id"],
                    groupable: true,
                    join: 'LEFT OUTER JOIN users as responsible ON ' +
                          "(#{WorkPackage.table_name}.responsible_id = responsible.id)"),
    QueryColumn.new(:updated_at,
                    sortable: "#{WorkPackage.table_name}.updated_at",
                    default_order: 'desc'),
    QueryColumn.new(:category,
                    sortable: "#{Category.table_name}.name",
                    groupable: true),
    QueryColumn.new(:fixed_version,
                    sortable: ["#{Version.table_name}.effective_date",
                               "#{Version.table_name}.name"],
                    default_order: 'desc',
                    groupable: true),
    # Put empty start_dates in the far future rather than in the far past
    QueryColumn.new(:start_date,
                    # Put empty start_dates in the far future rather than in the far past
                    sortable: ["CASE WHEN #{WorkPackage.table_name}.start_date IS NULL
                                THEN 1
                                ELSE 0 END",
                               "#{WorkPackage.table_name}.start_date"]),
    QueryColumn.new(:due_date,
                    # Put empty due_dates in the far future rather than in the far past
                    sortable: ["CASE WHEN #{WorkPackage.table_name}.due_date IS NULL
                                THEN 1
                                ELSE 0 END",
                               "#{WorkPackage.table_name}.due_date"]),
    QueryColumn.new(:estimated_hours,
                    sortable: "#{WorkPackage.table_name}.estimated_hours",
                    summable: true),
    QueryColumn.new(:spent_hours,
                    sortable: false,
                    summable: false),
    QueryColumn.new(:done_ratio,
                    sortable: "#{WorkPackage.table_name}.done_ratio",
                    groupable: true),
    QueryColumn.new(:created_at,
                    sortable: "#{WorkPackage.table_name}.created_at",
                    default_order: 'desc')
  ]
  cattr_reader :available_columns

  def self.new_default(attributes = nil)
    new(attributes).tap do |query|
      query.add_default_filter
      query.set_default_sort
      query.show_hierarchies = true
    end
  end

  after_initialize :set_context
  # For some reasons the filters loose their context
  # between the after_save and the after_commit callback.
  after_commit :set_context

  def set_context
    # We need to set the project for each filter if a project
    # is present because the information is not available when
    # deserializing the filters from the db.

    # Allow to use AR's select(...) without
    # the filters attribute
    return unless respond_to?(:filters)

    filters.each do |filter|
      filter.context = self
    end
  end

  def set_default_sort
    return if sort_criteria.any?

    self.sort_criteria = [['parent', 'desc']]
  end

  def context
    self
  end

  def add_default_filter
    return unless filters.blank?

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
    available_names = available_columns.map(&:name).map(&:to_s)

    column_names.each do |name|
      unless available_names.include? name.to_s
        errors.add :column_names, I18n.t(:error_invalid_query_column, value: name)
      end
    end
  end

  def validate_sort_criteria
    available_criteria = sortable_columns.map(&:name).map(&:to_s)

    sort_criteria.each do |name, _dir|
      unless available_criteria.include? name.to_s
        errors.add :sort_criteria, I18n.t(:error_invalid_sort_criterion, value: name)
      end
    end
  end

  def validate_group_by
    unless group_by.blank? || groupable_columns.map(&:name).map(&:to_s).include?(group_by.to_s)
      errors.add :group_by, I18n.t(:error_invalid_group_by, value: group_by)
    end
  end

  def validate_show_hierarchies
    if show_hierarchies && group_by.present?
      errors.add :show_hierarchies, :group_by_hierarchies_exclusive, group_by: group_by
    end
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (!is_public && user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public && !for_all? && user.allowed_to?(:manage_public_queries, project)
  end

  def add_filter(field, operator, values)
    filter = filter_for(field)

    filter.operator = operator
    filter.values = values

    filters << filter
  end

  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/\A(o|c|!\*|!|\*)?(.*)\z/).first
    add_filter field, (parms[0] || '='), [parms[1] || '']
  end

  # Add multiple filters using +add_filter+
  def add_filters(fields, operators, values)
    values ||= {}

    if fields.is_a?(Array) && operators.respond_to?(:[]) && values.respond_to?(:[])
      fields.each do |field|
        add_filter(field, operators[field], values[field])
      end
    end
  end

  def has_filter?(field)
    filters.present? && filters.any? { |f| f.field.to_s == field.to_s }
  end

  def filter_for(field)
    filter = (filters || []).detect { |f| f.field.to_s == field.to_s } || super(field)

    filter.context = self

    filter
  end

  def filtered?
    filters.any?
  end

  def normalized_name
    name.parameterize.underscore
  end

  def available_columns
    if @available_columns &&
       (@available_columns_project == (project && project.cache_key || 0))
      return @available_columns
    end

    @available_columns_project = project && project.cache_key || 0
    @available_columns = ::Query.available_columns + custom_field_columns

    # have to use this instead of
    # #select! as #select! can return nil
    @available_columns = @available_columns.select(&:available?)
  end

  def self.available_columns=(v)
    self.available_columns = v
  end

  def self.all_columns
    WorkPackageCustomField
      .all
      .map { |cf| ::QueryCustomFieldColumn.new(cf) }
      .concat(available_columns)
  end

  def self.groupable_columns
    all_columns.select(&:groupable)
  end

  def self.sortable_columns
    all_columns.select(&:sortable)
  end

  def self.add_available_column(column)
    available_columns << column if column.is_a?(QueryColumn)
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
    column_sortability = available_columns.inject({}) do |h, column|
      h[column.name.to_s] = column.sortable
      h
    end

    { 'id' => "#{WorkPackage.table_name}.id" }
      .merge(column_sortability)
  end

  def columns
    if has_default_columns?
      available_columns.select do |c|
        # Adds the project column by default for cross-project lists
        Setting.work_package_list_default_columns.include?(c.name.to_s) || (c.name == :project && project.nil?)
      end
    else
      # preserve the column_names order
      column_names.map { |name| available_columns.find { |col| col.name == name } }.compact
    end
  end

  def column_names=(names)
    if names.present?
      names = names.inject([]) { |out, e| out += e.to_s.split(',') }
      names = names.select { |n| n.is_a?(Symbol) || !n.blank? }
      names = names.map { |n| n.is_a?(Symbol) ? n : n.to_sym }
      # Set column_names to nil if default columns
      if names.map(&:to_s) == Setting.work_package_list_default_columns
        names = nil
      end
    end
    write_attribute(:column_names, names)
  end

  def has_column?(column)
    column_names && column_names.include?(column.name)
  end

  def has_default_columns?
    column_names.empty?
  end

  ##
  # Returns the columns involved in this query, including those only needed for sorting or grouping
  # puposes, not only the ones displayed (see :columns).
  def involved_columns
    columns = self.columns.map(&:name)

    columns << group_by.to_sym if group_by
    columns += sort_criteria.map { |x| x.first.to_sym }

    columns.uniq
  end

  def sort_criteria=(arg)
    if arg.is_a?(Hash)
      arg = arg.keys.sort.map { |k| arg[k] }
    end
    c = arg.reject { |k, _o| k.to_s.blank? }.slice(0, 3).map { |k, o| [k.to_s, o == 'desc' ? o : 'asc'] }
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_sql
    criteria = SortHelper::SortCriteria.new
    criteria.available_criteria = sortable_key_by_column_name
    criteria.criteria = sort_criteria
    criteria.to_sql
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end

  def sort_criteria_columns
    sort_criteria.map do |attribute, direction|
      attribute = attribute.to_sym

      column = sortable_columns
               .detect { |candidate| candidate.name == attribute }

      [column, direction]
    end
  end

  def sorted?
    sort_criteria.any?
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if grouped? && (column = group_by_column)
      Array(column.sortable).map { |s| "#{s} #{column.default_order}" }.join(',')
    end
  end

  # Returns true if the query is a grouped query
  def grouped?
    !group_by_column.nil?
  end

  def display_sums?
    display_sums && any_summable_columns?
  end

  def any_summable_columns?
    Setting.work_package_list_summable_columns.any?
  end

  def group_by_column
    groupable_columns.detect { |c| c.groupable && c.name.to_s == group_by }
  end

  def group_by_statement
    group_by_column.try(:groupable)
  end

  def project_statement
    project_clauses = []
    subproject_filter = filter_for 'subproject_id'
    if project && !project.descendants.active.empty?
      ids = [project.id]
      if subproject_filter
        case subproject_filter.operator
        when '='
          # include the selected subprojects
          ids += subproject_filter.values.each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += project.descendants.pluck(:id)
        end
      elsif Setting.display_subprojects_work_packages?
        ids += project.descendants.pluck(:id)
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    project_clauses.join(' AND ')
  end

  def statement
    filters_clauses = if filters.present? and valid?
                        filters
                          .reject { |f| f.field.to_s == 'subproject_id' }
                          .map do |filter|
                            "(#{filter.where})"
                          end
                      else
                        []
                      end

    (filters_clauses << project_statement).reject(&:empty?).join(' AND ')
  end

  # Returns the result set
  # Valid options are :order, :include, :conditions
  def results(options = {})
    Results.new(self, options)
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

  # Note: Convenience method to allow the angular front end to deal with query
  # menu items in a non implementation-specific way
  def starred
    !!query_menu_item
  end

  private

  def for_all?
    @for_all ||= project.nil?
  end

  def custom_field_columns
    if project
      project.all_work_package_custom_fields
    else
      WorkPackageCustomField.all
    end.map { |cf| ::QueryCustomFieldColumn.new(cf) }
  end
end
