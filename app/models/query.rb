#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

class Query < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include Queries::WorkPackages::AvailableFilterOptions

  alias_method :available_filters, :available_work_package_filters # referenced in plugin patches - currently there are only work package queries and filters

  @@user_filters = %w{assigned_to_id author_id watcher_id responsible_id}.freeze

  belongs_to :project
  belongs_to :user
  has_one :query_menu_item, class_name: 'MenuItems::QueryMenuItem', dependent: :delete, order: 'name', foreign_key: 'navigatable_id'
  serialize :filters, Queries::WorkPackages::FilterSerializer
  serialize :column_names
  serialize :sort_criteria, Array

  attr_protected :project_id # , :user_id

  validates :name, presence: true
  validates_length_of :name, maximum: 255

  validate :validate_work_package_filters

  after_initialize :remember_project_scope

  # WARNING: sortable should not contain a column called id (except for the
  # work_packages.id column). Otherwise naming collisions can happen when AR
  # optimizes a query into two separate DB queries (e.g. when joining tables).
  # The first query is employed to fetch all ids which are used as filters in
  # the second query. The columns mentioned in sortable are used for the first
  # query.  If such a statement selects from two coluns named <table name>.id
  # the second one is taken to get the ids of the work packages.
  @@available_columns = [
    QueryColumn.new(:id, sortable: "#{WorkPackage.table_name}.id", groupable: false),
    QueryColumn.new(:project, sortable: "#{Project.table_name}.name", groupable: true),
    QueryColumn.new(:type, sortable: "#{Type.table_name}.position", groupable: true),
    QueryColumn.new(:parent, sortable: ["#{WorkPackage.table_name}.root_id", "#{WorkPackage.table_name}.lft ASC"], default_order: 'desc'),
    QueryColumn.new(:status, sortable: "#{Status.table_name}.position", groupable: true),
    QueryColumn.new(:priority, sortable: "#{IssuePriority.table_name}.position", default_order: 'desc', groupable: true),
    QueryColumn.new(:subject, sortable: "#{WorkPackage.table_name}.subject"),
    QueryColumn.new(:author),
    QueryColumn.new(:assigned_to, sortable: ["#{User.table_name}.lastname",
                                             "#{User.table_name}.firstname",
                                             "#{WorkPackage.table_name}.assigned_to_id"],
                                  groupable: true),
    QueryColumn.new(:responsible, sortable: ["#{User.table_name}.lastname",
                                             "#{User.table_name}.firstname",
                                             "#{WorkPackage.table_name}.responsible_id"],
                                  groupable: "#{WorkPackage.table_name}.responsible_id",
                                  join: 'LEFT OUTER JOIN users as responsible ON ' +
                                        "(#{WorkPackage.table_name}.responsible_id = responsible.id)"),
    QueryColumn.new(:updated_at, sortable: "#{WorkPackage.table_name}.updated_at", default_order: 'desc'),
    QueryColumn.new(:category, sortable: "#{Category.table_name}.name", groupable: true),
    QueryColumn.new(:fixed_version, sortable: ["#{Version.table_name}.effective_date", "#{Version.table_name}.name"], default_order: 'desc', groupable: true),
    # Put empty start_dates and due_dates in the far future rather than in the far past
    QueryColumn.new(:start_date, sortable: ["CASE WHEN #{WorkPackage.table_name}.start_date IS NULL THEN 1 ELSE 0 END", "#{WorkPackage.table_name}.start_date"]),
    QueryColumn.new(:due_date, sortable: ["CASE WHEN #{WorkPackage.table_name}.due_date IS NULL THEN 1 ELSE 0 END", "#{WorkPackage.table_name}.due_date"]),
    QueryColumn.new(:estimated_hours, sortable: "#{WorkPackage.table_name}.estimated_hours"),
    QueryColumn.new(:done_ratio, sortable: "#{WorkPackage.table_name}.done_ratio", groupable: true),
    QueryColumn.new(:created_at, sortable: "#{WorkPackage.table_name}.created_at", default_order: 'desc'),
  ]
  cattr_reader :available_columns

  def initialize(attributes = nil, options = {})
    super
    add_default_filter if options[:initialize_with_default_filter]
  end

  def add_default_filter
    self.filters = [Queries::WorkPackages::Filter.new('status_id', operator: 'o', values: [''])] if filters.blank?
  end

  # Store the fact that project is nil (used in #editable_by?)
  def remember_project_scope
    @is_for_all = project.nil?
  end

  def validate_work_package_filters
    filters.each do |filter|
      unless filter.valid?
        messages = filter.errors.messages.values.flatten.join(" #{I18n.t('support.array.sentence_connector')} ")
        cf_id = custom_field_id filter

        if cf_id && CustomField.find(cf_id)
          attribute_name = CustomField.find(cf_id).name
          errors.add :base, attribute_name + I18n.t(default: ' %{message}', message:   messages)
        else
          attribute_name = WorkPackage.human_attribute_name(filter.field)
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
    is_public && !@is_for_all && user.allowed_to?(:manage_public_queries, project)
  end

  def add_filter(field, operator, values)
    return unless work_package_filter_available?(field)

    if filter = filter_for(field)
      filter.operator = operator
      filter.values = values
    else
      filters << Queries::WorkPackages::Filter.new(field, operator: operator, values: values)
    end
  end

  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/\A(o|c|!\*|!|\*)?(.*)\z/).first
    add_filter field, (parms[0] || '='), [parms[1] || '']
  end

  # Add multiple filters using +add_filter+
  def add_filters(fields, operators, values)
    values ||= {}

    if fields.is_a?(Array) && operators.is_a?(Hash) && values.is_a?(Hash)
      fields.each do |field|
        add_filter(field, operators[field], values[field])
      end
    end
  end

  def has_filter?(field)
    filters.present? && filters.any? { |filter| filter.field.to_s == field.to_s }
  end

  def filter_for(field)
    (filters || []).detect { |filter| filter.field.to_s == field.to_s }
  end

  # Deprecated
  def operator_for(field)
    warn '#operator_for is deprecated. Query the filter object directly, instead.'
    filter_for(field).try :operator
  end

  # Deprecated
  def values_for(field)
    warn '#values_for is deprecated. Query the filter object directly, instead.'
    filter_for(field).try :values
  end

  def label_for(field)
    label = available_work_package_filters[field][:name] if work_package_filter_available?(field)
    label ||= field.gsub(/\_id\z/, '')
  end

  def normalized_name
    name.parameterize.underscore
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = ::Query.available_columns
    @available_columns += (project ?
                            project.all_work_package_custom_fields :
                            WorkPackageCustomField.find(:all)
                           ).map { |cf| ::QueryCustomFieldColumn.new(cf) }
    if WorkPackage.done_ratio_disabled?
      @available_columns.select! { |column| column.name != :done_ratio }.length
    end
    @available_columns
  end

  def self.available_columns=(v)
    self.available_columns = (v)
  end

  def self.add_available_column(column)
    available_columns << (column) if column.is_a?(QueryColumn)
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select(&:groupable)
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
    { 'id' => "#{WorkPackage.table_name}.id" }.merge(available_columns.inject({}) {|h, column|
                                                       h[column.name.to_s] = column.sortable
                                                       h
                                                     })
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
    column_names.nil? || column_names.empty?
  end

  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.map { |k| arg[k] }
    end
    c = arg.select { |k, _o| !k.to_s.blank? }.slice(0, 3).map { |k, o| [k.to_s, o == 'desc' ? o : 'asc'] }
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if grouped? && (column = group_by_column)
      column.sortable.is_a?(Array) ?
        column.sortable.map { |s| "#{s} #{column.default_order}" }.join(',') :
        "#{column.sortable} #{column.default_order}"
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
    if project && !project.descendants.active.empty?
      ids = [project.id]
      subproject_filter = filter_for 'subproject_id'
      if subproject_filter
        case subproject_filter.operator
        when '='
          # include the selected subprojects
          ids += subproject_filter.values.each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += project.descendants.map(&:id)
        end
      elsif Setting.display_subprojects_work_packages?
        ids += project.descendants.map(&:id)
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    project_clauses <<  WorkPackage.visible_condition(User.current)
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
          project_ids = User.current.projects_by_role.map { |r, p| p if r.permissions.include? :view_work_package_watchers }.flatten.compact.map(&:id).uniq
          sql_parts << "#{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='WorkPackage' AND #{sql_for_field field, '=', values, db_table, db_field})"\
                       " AND #{Project.table_name}.id IN (#{project_ids.join(',')})" unless project_ids.empty?
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
          groups = Group.find_all_by_id(values)
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
          roles = roles.find_all_by_id(values)
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

    (filters_clauses << project_statement).join(' AND ')
  end

  # Returns the result set
  # Valid options are :order, :include, :conditions
  def results(options = {})
    Results.new(self, options)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def work_package_journals(options = {})
    query = Journal.includes(:user)
            .where(journable_type: WorkPackage.to_s)
            .joins('INNER JOIN work_packages ON work_packages.id = journals.journable_id')
            .joins('INNER JOIN projects ON work_packages.project_id = projects.id')
            .joins('INNER JOIN users AS authors ON work_packages.author_id = authors.id')
            .joins('INNER JOIN types ON work_packages.type_id = types.id')
            .joins('INNER JOIN statuses ON work_packages.status_id = statuses.id')
            .where(statement)
            .order(options[:order])
            .limit(options[:limit])
            .offset(options[:offset])

    query.find :all
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  # Note: Convenience method to allow the angular front end to deal with query menu items in a non implementation-specific way
  def starred
    !!query_menu_item
  end

  private

  def custom_field_id(filter)
    matchdata = /cf\_(?<id>\d+)/.match(filter.field.to_s)

    matchdata.nil? ? nil : matchdata[:id]
  end

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter = false)
    sql = ''
    case operator
    when '='
      if value.present?
        if value.include?('-1')
          sql = "#{db_table}.#{db_field} IS NULL OR "
        end

        sql += "#{db_table}.#{db_field} IN (" + value.map { |val| "'#{connection.quote_string(val)}'" }.join(',') + ')'
      else
        # empty set of allowed values produces no result
        sql = '0=1'
      end
    when '!'
      if value.present?
        sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.map { |val| "'#{connection.quote_string(val)}'" }.join(',') + '))'
      else
        # empty set of forbidden values allows all results
        sql = '1=1'
      end
    when '!*'
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when '*'
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when '>='
      if is_custom_filter
        sql = "#{db_table}.#{db_field} != '' AND CAST(#{db_table}.#{db_field} AS decimal(60,4)) >= #{value.first.to_f}"
      else
        sql = "#{db_table}.#{db_field} >= #{value.first.to_f}"
      end
    when '<='
      if is_custom_filter
        sql = "#{db_table}.#{db_field} != '' AND CAST(#{db_table}.#{db_field} AS decimal(60,4)) <= #{value.first.to_f}"
      else
        sql = "#{db_table}.#{db_field} <= #{value.first.to_f}"
      end
    when 'o'
      sql = "#{Status.table_name}.is_closed=#{connection.quoted_false}" if field == 'status_id'
    when 'c'
      sql = "#{Status.table_name}.is_closed=#{connection.quoted_true}" if field == 'status_id'
    when '>t-'
      sql = date_range_clause(db_table, db_field, - value.first.to_i, 0)
    when '<t-'
      sql = date_range_clause(db_table, db_field, nil, - value.first.to_i)
    when 't-'
      sql = date_range_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when '>t+'
      sql = date_range_clause(db_table, db_field, value.first.to_i, nil)
    when '<t+'
      sql = date_range_clause(db_table, db_field, 0, value.first.to_i)
    when 't+'
      sql = date_range_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when 't'
      sql = date_range_clause(db_table, db_field, 0, 0)
    when 'w'
      from = l(:general_first_day_of_week) == '7' ?
      # week starts on sunday
      ((Date.today.cwday == 7) ? Time.now.at_beginning_of_day : Time.now.at_beginning_of_week - 1.day) :
        # week starts on monday (Rails default)
        Time.now.at_beginning_of_week
      sql = "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(from + 7.days)]
    when '~'
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when '!~'
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    end

    sql
  end

  # Returns a SQL clause for a date or datetime field.
  def date_range_clause(table, field, from, to)
    s = []
    if from
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date((Date.yesterday + from).to_time.end_of_day)])
    end
    if to
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date((Date.today + to).to_time.end_of_day)])
    end
    s.join(' AND ')
  end
end
