#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

# rubocop:disable Style/ClassCheck
#   Prefer `kind_of?` over `is_a?` because it reads well before vowel and consonant sounds.
#   E.g.: `relation.kind_of? ActiveRecord::Relation`

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/PerceivedComplexity

# In the context of the baseline-comparison feature, this class represents an active-record relation
# that queries historic data, i.e. performs its query e.g. on the `work_package_journals` table
# rather than the `work_packages` table.
#
# Usage:
#
#     timestamp = 1.year.ago
#     active_record_relation = WorkPackage.where(subject: "Foo")
#     historic_relation = Journable::HistoricActiveRecordRelation.new(active_record_relation, timestamp:)
#
# See also:
#
# - https://github.com/opf/openproject/pull/11243
# - https://community.openproject.org/projects/openproject/work_packages/26448
#
class Journable::HistoricActiveRecordRelation < ActiveRecord::Relation
  attr_accessor :timestamp

  include ActiveRecord::Delegation::ClassSpecificRelation

  def initialize(relation, timestamp:)
    raise ArgumentError, "Expected ActiveRecord::Relation" unless relation.kind_of? ActiveRecord::Relation

    super(relation.klass)
    relation.instance_variables.each do |key|
      instance_variable_set key, relation.instance_variable_get(key)
    end

    self.timestamp = Array(timestamp)
    readonly!
    instance_variable_set :@table, model.journal_class.arel_table
  end

  # We need to patch the `pluck` method of an active-record relation that
  # queries historic data (i.e. journal data). Otherwise, `pluck(:id)`
  # would return the `id` of the journal table rather than the `id` of the
  # journable table, which would be expected from the syntax:
  #
  #     WorkPackage.where(assigned_to_id: 123).at_timestamp(1.year.ago).pluck(:id)
  #
  def pluck(*column_names)
    column_names.map! do |column_name|
      case column_name
      when :id, "id"
        "journals.journable_id"
      when :created_at, "created_at"
        "journables.created_at"
      when :updated_at, "updated_at"
        "journals.updated_at"
      else
        if model.column_names_missing_in_journal.include?(column_name.to_s)
          Rails.logger.warn "Cannot pluck column `#{column_name}` because this attribute is not journalized," \
                            "i.e. it is missing in the #{journal_class.table_name} table."
          "null as #{column_name}"
        else
          column_name
        end
      end
    end
    arel
    super
  end

  alias_method :original_build_arel, :build_arel

  # Patch the arel object, which is used to construct the sql query, in order
  # to modify the query to search for historic data.
  #
  def build_arel(aliases = nil)
    relation = self

    relation = switch_to_journals_database_table(relation)
    relation = substitute_join_tables_in_where_clause(relation)
    relation = substitute_database_table_in_where_clause(relation)
    relation = add_timestamp_condition(relation)
    relation = add_join_on_journables_table_with_created_at_column(relation)
    relation = add_join_projects_on_work_package_journals(relation)
    relation = select_columns_from_the_appropriate_tables(relation)

    # Based on the previous modifications, build the algebra object.
    arel = relation.call_original_build_arel(aliases)
    arel = modify_where_clauses(arel)
    arel = modify_order_clauses(arel)
    modify_joins(arel)
  end

  def call_original_build_arel(aliases = nil)
    original_build_arel(aliases)
  end

  def eager_loading?
    false
  end

  private

  # Switch the database table, e.g. from `work_packages` to `work_package_journals`.
  #
  def switch_to_journals_database_table(relation)
    relation.instance_variable_set :@table, model.journal_class.arel_table
    relation
  end

  # Modify the where clauses such that e.g. the work-packages table is substituted
  # with the work-package-journals table.
  #
  # When the where clause contains the `id` column, use `journals.journable_id` instead.
  #
  def substitute_database_table_in_where_clause(relation)
    relation.where_clause.instance_variable_get(:@predicates).each do |predicate|
      substitute_database_table_in_predicate(predicate)
    end
    relation
  end

  # In sql, a *predicate* is an expression that evaluates to `true`, `false` or "unknown". [1]
  # In active-record relations, predicates are components of where clauses.
  #
  # We need to substitute the table name ("work_packages") with the journalized table name
  # ("work_package_journals") in order to retrieve historic data from the journalized table.
  #
  # However, there are columns where we need to retrieve the data from another table,
  # in particular:
  #
  # - `id`
  # - `created_at`
  # - `updated_at`
  #
  # When asking for `WorkPackage.at_timestamp(...).where(id: 123)`, we are expecting `id` to refer
  # to the id of the work package, not of the journalized table entry.
  #
  # Also, the `created_at` and `updated_at` columns are not included in the journalized table.
  # We gather the `updated_at` from the `journals` mapping table, and the `created_at` from the
  # model's table (`work_packages`) itself.
  #
  # [1] https://learn.microsoft.com/en-us/sql/t-sql/queries/predicates
  #
  def substitute_database_table_in_predicate(predicate)
    case predicate
    when String
      gsub_table_names_in_sql_string!(predicate)
    when Arel::Nodes::HomogeneousIn,
         Arel::Nodes::In,
         Arel::Nodes::NotIn,
         Arel::Nodes::Equality,
         Arel::Nodes::NotEqual,
         Arel::Nodes::LessThan,
         Arel::Nodes::LessThanOrEqual,
         Arel::Nodes::GreaterThan,
         Arel::Nodes::GreaterThanOrEqual
      if predicate.left.relation == arel_table or predicate.left.relation == journal_class.arel_table
        case predicate.left.name
        when "id"
          predicate.left.name = "journable_id"
          predicate.left.relation = Journal.arel_table
        when "updated_at"
          predicate.left.relation = Journal.arel_table
        when "created_at"
          predicate.left = Arel::Nodes::SqlLiteral.new("\"journables\".\"created_at\"")
        else
          predicate.left.relation = journal_class.arel_table
        end
      end
    when Arel::Nodes::Grouping
      substitute_database_table_in_predicate(predicate.expr.left)
      substitute_database_table_in_predicate(predicate.expr.right)
    else
      raise NotImplementedError, "FIXME A predicate of type #{predicate.class.name} is not handled, yet."
    end
  end

  # Additional table joins can appear in the where clause, such as the custom_values table join.
  # We need to substitute the table name ("custom_values") with the journalized table name
  # ("customized_journals") in order to retrieve historic data from the journalized table.

  def substitute_join_tables_in_where_clause(relation)
    relation.where_clause.instance_variable_get(:@predicates).each do |predicate|
      substitute_custom_values_join_in_predicate(predicate)
    end
    relation
  end

  # For simplicity's sake we replace the "custom_values" join only when the predicate is a String.
  # This is the way we are receiving the predicate from the `Queries::WorkPackages::Filter::CustomFieldFilter`
  # The joins are defined in the `Queries::WorkPackages::Filter::CustomFieldContext#where_subselect_joins`
  # method. If we ever change that method to use Arel, we will need to implement the substitution
  # for Arel objects as well.
  def substitute_custom_values_join_in_predicate(predicate)
    if predicate.is_a? String
      predicate.gsub! /JOIN (?<!_)#{CustomValue.table_name}/, "JOIN #{Journal::CustomizableJournal.table_name}"
      predicate.gsub! "JOIN \"#{CustomValue.table_name}\"", "JOIN \"#{Journal::CustomizableJournal.table_name}\""

      customized_type = /custom_values.customized_type = 'WorkPackage'/
      customized_id   = /custom_values.customized_id = work_packages.id/

      # The customizable_journals table has no direct relation to the work_packages table,
      # but it has to the journals table. We join it to the journals table instead.
      journal_id = "customizable_journals.journal_id = journals.id"

      predicate.gsub! /#{customized_type}.*AND #{customized_id}/m, journal_id
    end
  end

  # Add a timestamp condition: Select the work package journals that are the
  # current ones at the given timestamp.
  #
  def add_timestamp_condition(relation)
    relation.joins_values = [journals_join_statement] + relation.joins_values

    timestamp_condition = timestamp.map do |t|
      Journal.where(journable_type: model.name).at_timestamp(t)
    end.reduce(&:or)

    relation.merge(timestamp_condition)
  end

  def journals_join_statement
    "INNER JOIN \"journals\" ON \"journals\".\"data_type\" = '#{model.journal_class.name}' " \
      "AND \"journals\".\"data_id\" = \"#{model.journal_class.table_name}\".\"id\""
  end

  # Join the journables table itself because we need to take the `created_at` attribute from that.
  # The `created_at` column is not present in the `work_package_journals` table.
  #
  def add_join_on_journables_table_with_created_at_column(relation)
    relation
        .joins("INNER JOIN (SELECT id, created_at " \
               "FROM \"#{model.table_name}\") AS journables " \
               "ON \"journables\".\"id\" = \"journals\".\"journable_id\"")
  end

  # Join the projects table on work_package_journals if :project is in the includes.
  # It is needed when projects are filtered by id, and has to be done manually
  # as eager_loading is disabled.
  # It needs to be `work_package_journals` and not `journables` (the subselect of the work_packages table)
  # because the journables table will contain the current project and not the project the work package was
  # in at the time of the journal.
  # Does not work yet for other includes.
  #
  def add_join_projects_on_work_package_journals(relation)
    if include_projects?
      relation
        .except(:includes, :eager_load, :preload)
        .joins('LEFT OUTER JOIN "projects" ' \
               'ON "projects"."id" = "work_package_journals"."project_id"')
    else
      relation
    end
  end

  def include_projects?
    include_values = values.fetch(:includes, [])
    include_values.include?(:project)
  end

  # Gather the columns we need in our model from the different tables in the sql query:
  #
  # - the `work_packages` table (journables)
  # - the `work_package_journals` table (data)
  # - the `journals` table
  #
  # Also, add the `timestamp` and `journal_id` as column so that we have it as attribute in our model.
  #
  def select_columns_from_the_appropriate_tables(relation)
    if relation.select_values.count == 0
      relation = relation.select(column_select_definitions.join(", "))
    elsif relation.select_values.count == 1 and
        relation.select_values.first.respond_to? :relation and
        relation.select_values.first.relation.name == model.journal_class.table_name and
        relation.select_values.first.name == "id"
      # For sub queries, we need to use the journals.journable_id as well.
      # See https://github.com/fiedl/openproject/issues/3.
      relation.instance_variable_get(:@values)[:select] = []
      relation = relation.select("journals.journable_id as id")
    end
    relation
  end

  def column_select_definitions
    [
      "#{model.journal_class.table_name}.*",
      "journals.journable_id as id",
      "journables.created_at as created_at",
      "journals.updated_at as updated_at",
      "CASE #{timestamp_case_when_statements} END as timestamp",
      "journals.id as journal_id"
    ] +
    model.column_names_missing_in_journal.collect do |missing_column_name|
      "null as #{missing_column_name}"
    end
  end

  # Modify order clauses to use the work-pacakge-journals table.
  #
  def modify_order_clauses(arel)
    arel.instance_variable_get(:@ast).instance_variable_get(:@orders).each do |order_clause|
      if order_clause.kind_of? Arel::Nodes::SqlLiteral
        gsub_table_names_in_sql_string!(order_clause)
      elsif order_clause.expr.relation == model.arel_table
        if order_clause.expr.name == "id"
          order_clause.expr.name = "journable_id"
          order_clause.expr.relation = Journal.arel_table
        else
          order_clause.expr.relation = model.journal_class.arel_table
        end
      end
    end
    arel
  end

  # Modify the joins to point to the journable_id.
  #
  def modify_joins(arel)
    arel.instance_variable_get(:@ast).instance_variable_get(:@cores).each do |core|
      core.instance_variable_get(:@source).right.each do |node|
        if node.kind_of? Arel::Nodes::StringJoin
          gsub_table_names_in_sql_string!(node.left)
        elsif node.kind_of?(Arel::Nodes::Join) and node.right.kind_of?(Arel::Nodes::On)
          [node.right.expr.left, node.right.expr.right].each do |attribute|
            if attribute.respond_to? :relation and
                (attribute.relation == journal_class.arel_table) and
                (attribute.name == "id")
              attribute.relation = Journal.arel_table
              attribute.name = "journable_id"
            end
          end
        end
      end
    end
    arel
  end

  def modify_where_clauses(arel)
    arel.instance_variable_get(:@ast).instance_variable_get(:@cores).each do |core|
      core.instance_variable_get(:@wheres).each do |where_clause|
        modify_conditions(where_clause)
      end
    end

    arel
  end

  def modify_conditions(node)
    if node.kind_of? Arel::TreeManager
      # We have another sub-tree, investigate its core, which is a SelectCore
      node.instance_variable_get(:@ast).instance_variable_get(:@cores).each do |core|
        modify_conditions(core)
      end
    elsif node.kind_of? Arel::Nodes::SelectStatement
      # A sub-select statement, we need to investigate its core, which is also a SelectCore
      modify_conditions(node.instance_variable_get(:@cores).first)

      # all the orders need to be modified as well
      node.instance_variable_get(:@orders).each do |order_clause|
        if order_clause.kind_of? Arel::Nodes::SqlLiteral
          gsub_table_names_in_sql_string!(order_clause)
        elsif order_clause.expr.relation == model.arel_table
          if order_clause.expr.name == "id"
            order_clause.expr.name = "journable_id"
            order_clause.expr.relation = Journal.arel_table
          else
            order_clause.expr.relation = model.journal_class.arel_table
          end
        end
      end
    elsif node.kind_of? Arel::Nodes::SelectCore
      # We have another SelectCore, which is the main part of the select statement.
      # Sources are the select table (left) and all joins (right)
      source = node.instance_variable_get(:@source)

      # when we are selecting from the model's table, we need to select from the journalized table instead
      if source.left == model.arel_table
        source.left = model.journal_class.arel_table

        # check if we are also joining the journals table, if not we need to add it
        if source.right.none? { |join_source| join_source.kind_of?(Arel::Nodes::Join) && join_source.left == Journal.arel_table }
          source.right << Arel::Nodes::StringJoin.new(Arel.sql(journals_join_statement_with_timestamps))
        end
      end

      # Check if we are joining the model's table, and if so, it will later be replaced by the journalized table, but as the
      # journalized table does not contain the model's ID we need to add another join to the journals table as well
      if source.right.any? { |join_source| join_source.kind_of?(Arel::Nodes::Join) && join_source.left == model.arel_table }
        source.right.unshift Arel::Nodes::StringJoin.new(Arel.sql(journals_join_statement_with_timestamps_and_members))
      end

      # go through all other joins and modify them as well
      source.right.each do |src|
        modify_conditions(src)
      end

      # all the fields in the select statement need to be modified as well
      projections = node.instance_variable_get(:@projections)
      projections.each do |projection|
        modify_conditions(projection)
      end

      # the where's need to be modified as well
      node.instance_variable_get(:@wheres).each do |wheres|
        modify_conditions(wheres)
      end
    elsif node.kind_of?(Arel::Nodes::On)
      # In an ON node we must not traverse down left and right directly (like other NodeExpressions) but go through the
      # expr, which is a NodeExpression itself
      [node.expr.left, node.expr.right].each { |child| modify_conditions(child) }
    elsif node.kind_of?(Arel::Attributes::Attribute)
      # We find an attribute, figure out if it is the model's table
      if node.relation == model.arel_table
        if node.name == "id"
          # ID needs to be pulled from the Journal table
          node.relation = Journal.arel_table
          node.name = "journable_id"
        else
          # all other attributes can be pulled from the journalized table
          node.relation = model.journal_class.arel_table
        end
      end
    elsif node.kind_of?(Arel::Nodes::Join)
      # We found another join, left is the table name, right is the ON condition, if it points to the model's table
      # replace it with the journalized table
      if node.left == model.arel_table
        node.left = model.journal_class.arel_table
      end
      # Go thorugh the ON condition and figure out if we need to rename attributes in there
      modify_conditions(node.right)
    elsif node.kind_of? Arel::Nodes::NodeExpression
      # Generic case, go through left and right
      modify_conditions(node.left) if node.respond_to?(:left) && node.left
      modify_conditions(node.right) if node.respond_to?(:right) && node.right
    end

    node
  end

  # Replace table names in sql strings, e.g.
  #
  #     "work_package.id"      => "journals.journable_id"
  #     "work_package.subject" => "work_package_journals.subject"
  #     "custom_values.*"      => "customizable_journals.*"
  #
  def gsub_table_names_in_sql_string!(sql_string)
    sql_string.gsub! /(?<!_)#{model.table_name}\.updated_at/, "journals.updated_at"
    sql_string.gsub! "\"#{model.table_name}\".\"updated_at\"", "\"journals\".\"updated_at\""
    sql_string.gsub! /(?<!_)#{model.table_name}\.created_at/, "journables.created_at"
    sql_string.gsub! "\"#{model.table_name}\".\"created_at\"", "\"journables\".\"created_at\""
    sql_string.gsub! /(?<!_)#{model.table_name}\.id/, "journals.journable_id"
    sql_string.gsub! "\"#{model.table_name}\".\"id\"", "\"journals\".\"journable_id\""
    sql_string.gsub! /(?<!_)#{model.table_name}\./, "#{model.journal_class.table_name}."
    sql_string.gsub! "\"#{model.table_name}\".", "\"#{model.journal_class.table_name}\"."
    sql_string.gsub! /(?<!_)#{CustomValue.table_name}\./, "#{Journal::CustomizableJournal.table_name}."
    sql_string.gsub! "\"#{CustomValue.table_name}\".", "\"#{Journal::CustomizableJournal.table_name}\"."
  end

  def timestamp_case_when_statements
    timestamp
      .map do |timestamp|
      comparison_time = case timestamp
                        when Timestamp
                          timestamp.to_time
                        when DateTime
                          timestamp.in_time_zone
                        else
                          raise NotImplementedError, "Unknown timestamp type: #{timestamp.class}"
                        end

      "WHEN \"journals\".\"validity_period\" @> timestamp with time zone '#{comparison_time}' THEN '#{timestamp}'"
    end
      .join(" ")
  end

  def journals_join_statement_with_timestamps_and_members
    journals_join_statement + <<~SQL.squish
      AND "journals"."journable_type" = "members"."entity_type"
      AND "journals"."journable_id" = "members"."entity_id"
    SQL
  end

  def journals_join_statement_with_timestamps
    statement = <<~SQL.squish
      INNER JOIN "journals" ON
        "journals"."data_type" = '#{model.journal_class.name}' AND
        "journals"."data_id" = "#{model.journal_class.table_name}"."id"
    SQL

    additional_conditions = timestamp
      .map do |timestamp|
      comparison_time = case timestamp
                        when Timestamp
                          timestamp.to_time
                        when DateTime
                          timestamp.in_time_zone
                        else
                          raise NotImplementedError, "Unknown timestamp type: #{timestamp.class}"
                        end
      "\"journals\".\"validity_period\" @> timestamp with time zone '#{comparison_time}'"
    end

    return statement if additional_conditions.blank?

    "#{statement} AND (#{additional_conditions.join(' OR ')})"
  end

  class NotImplementedError < StandardError; end
end

# rubocop:enable Style/ClassCheck
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/PerceivedComplexity
