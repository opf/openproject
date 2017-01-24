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
  include Queries::SqlForField

  @@user_filters = %w{assigned_to_id author_id watcher_id responsible_id}.freeze

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

  scope :visible, ->(to:) do
    # User can see public queries and his own queries
    scope = where(is_public: true)

    if to.logged?
      scope.or(where(user_id: to.id))
    else
      scope
    end
  end

  scope :global, -> {
    where(project_id: nil)
  }

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
                    sortable: ["#{WorkPackage.table_name}.root_id",
                               "#{WorkPackage.table_name}.lft ASC"],
                    default_order: 'desc'),
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

  def initialize(attributes = nil, options = {})
    super(attributes)
    add_default_filter if options[:initialize_with_default_filter]
  end

  after_initialize :set_context

  def set_context
    # We need to set the project for each filter if a project
    # is present because the information is not available when
    # deserializing the filters from the db.

    # Allow to use AR's select(...) without
    # the filters attribute
    return unless respond_to?(:filters)

    filters.each do |filter|
      filter.context = project
    end
  end

  alias :context :project

  def add_default_filter
    return unless filters.blank?

    add_filter('status_id', 'o', [''])
  end

  def validate_work_package_filters
    filters.each do |filter|
      unless filter.valid?
        messages = filter
                   .errors
                   .messages
                   .values
                   .flatten
                   .join(" #{I18n.t('support.array.sentence_connector')} ")

        attribute_name = filter.human_name

        # TODO: check if this can be handled without the case statment
        case filter
        when Queries::WorkPackages::Filter::CustomFieldFilter
          errors.add :base, attribute_name + I18n.t(default: ' %{message}', message: messages)
        else
          errors.add :base, errors.full_message(attribute_name, messages)
        end
      end
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

    filter.context = project

    filter
  end

  def filtered?
    filters.any?
  end

  def normalized_name
    name.parameterize.underscore
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = ::Query.available_columns
    @available_columns += if project
                            project.all_work_package_custom_fields(include: :translations)
                          else
                            WorkPackageCustomField.includes(:translations).all
                          end.map { |cf| ::QueryCustomFieldColumn.new(cf) }

    # have to use this instead of
    # #select! as #select! can return nil
    @available_columns = @available_columns.select(&:available?)
  end

  def self.available_columns=(v)
    self.available_columns = v
  end

  def self.add_available_column(column)
    available_columns << column if column.is_a?(QueryColumn)
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select(&:groupable)
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
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
    c = arg.select { |k, _o| !k.to_s.blank? }.slice(0, 3).map { |k, o| [k.to_s, o == 'desc' ? o : 'asc'] }
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_sql
    criteria = SortHelper::SortCriteria.new
    criteria.available_criteria = sortable_columns
    criteria.criteria = sort_criteria
    criteria.to_sql
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
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
    # filters clauses
    filters_clauses = []
    filters.each do |filter|
      field = filter.field.to_s
      next if field == 'subproject_id'

      operator = filter.operator
      values = filter.values ? filter.values.clone : [''] # HACK - some operators don't require values, but they are needed for building the statement

      # "me" value substitution
      if @@user_filters.include? field
        if values.delete('me')
          if User.current.logged?
            values.push(User.current.id.to_s)
            values += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
          else
            values.push('0')
          end
        end
      end

      sql = ''
      if field =~ /\Acf_(\d+)\z/
        # custom field
        db_table = CustomValue.table_name
        db_field = 'value'
        is_custom_filter = true
        sql << "#{WorkPackage.table_name}.id IN (SELECT #{WorkPackage.table_name}.id FROM #{WorkPackage.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='WorkPackage' AND #{db_table}.customized_id=#{WorkPackage.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
        sql << sql_for_field(field, operator, values, db_table, db_field, true) + ')'
      elsif field == 'watcher_id'
        db_table = Watcher.table_name
        db_field = 'user_id'
        if User.current.admin?
          # Admins can always see all watchers
          sql << "#{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='WorkPackage' AND #{sql_for_field field, '=', values, db_table, db_field})"
        else
          sql_parts = []
          if User.current.logged? && user_id = values.delete(User.current.id.to_s)
            # a user can always see his own watched issues
            sql_parts << "#{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='WorkPackage' AND #{sql_for_field field, '=', [user_id], db_table, db_field})"
          end
          # filter watchers only in projects the user has the permission to view watchers in
          sql_parts << <<-SQL
            #{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'}
              (SELECT #{db_table}.watchable_id
               FROM #{db_table}
               WHERE #{db_table}.watchable_type='WorkPackage'
                 AND #{sql_for_field field, '=', values, db_table, db_field})
                 AND #{Project.table_name}.id IN
                   (#{Project.allowed_to(User.current, :view_work_package_watchers).select("#{Project.table_name}.id").to_sql})
          SQL
          sql << "(#{sql_parts.join(' OR ')})"
        end
      elsif field == 'member_of_group' # named field
        if operator == '*' # Any group
          groups = Group.all
          operator = '=' # Override the operator since we want to find by assigned_to
        elsif operator == '!*'
          groups = Group.all
          operator = '!' # Override the operator since we want to find by assigned_to
        else
          groups = Group.where(id: values)
        end
        groups ||= []
        members_of_groups = groups.inject([]) {|user_ids, group|
          if group && group.user_ids.present?
            user_ids << group.user_ids
          end
          user_ids.flatten.uniq.compact
        }.sort.map(&:to_s)

        sql << '(' + sql_for_field('assigned_to_id', operator, members_of_groups, WorkPackage.table_name, 'assigned_to_id', false) + ')'

      elsif field == 'assigned_to_role' # named field
        roles = Role.givable
        if operator == '*' # Any Role
          operator = '=' # Override the operator since we want to find by assigned_to
        elsif operator == '!*' # No role
          operator = '!' # Override the operator since we want to find by assigned_to
        else
          roles = roles.where(id: values)
        end
        roles ||= []

        members_of_roles = roles.inject([]) {|user_ids, role|
          if role && role.members
            user_ids << if project_id
                          role.members.reject { |m| m.project_id != project_id }.map(&:user_id)
                        else
                          role.members.map(&:user_id)
                        end
          end
          user_ids.flatten.uniq.compact
        }.sort.map(&:to_s)

        sql << '(' + sql_for_field('assigned_to_id', operator, members_of_roles, WorkPackage.table_name, 'assigned_to_id', false) + ')'
      else
        # regular field
        db_table = WorkPackage.table_name
        db_field = field
        sql << '(' + sql_for_field(field, operator, values, db_table, db_field) + ')'
      end
      filters_clauses << sql
    end if filters.present? and valid?

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
end
