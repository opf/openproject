# frozen_string_literal: true

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
    raise ArgumentError, "Expected ActiveRecord::Relation" unless relation.is_a? ActiveRecord::Relation

    super(relation.klass)
    relation.instance_variables.each do |key|
      instance_variable_set key, relation.instance_variable_get(key)
    end

    self.timestamp = Array(timestamp)
    readonly!
  end

  # Patch the `pluck` method of an active-record relation
  # so that columns callers might expect but that do not exist on the journals table are ignored.
  def pluck(*column_names)
    column_names.map! do |column_name|
      if model.column_names_missing_in_journal.include?(column_name.to_s)
        Rails.logger.warn "Cannot pluck column `#{column_name}` because this attribute is not journalized," \
                          "i.e. it is missing in the #{journal_class.table_name} table."
        Arel::Nodes::SqlLiteral.new("NULL").as(column_name.to_s)
      else
        column_name
      end
    end

    super
  end

  # Patch the arel object, which is used to construct the sql query, in order
  # to modify the query to search for historic data.
  #
  # The way this is done is by prepending a CTE to the list of possible already defined CTEs
  # under the name of the model the historic data is queried on. The CTE will then be on the
  # join of:
  # * the model's data journal (for the property values at the time)
  # * the journals table itself (for the update timestamp)
  # * the model table (for the creation timestamp)
  # The result is that all later statements, including later CTEs, will pick up data from that
  # first CTE. This makes the fact that data is fetched not from the model but from the journals
  # transparent so most queries that work on the model table just continue to work on the journals
  # join. The only currently known exceptions to this are conditions on custom fields. That is
  # because those should also work on the historic data and not the current one, so the statement
  # needs to be rewritten.
  #
  # A statement on work packages might then look like this:
  #
  # WITH work_packages AS (
  #     [SQL join on work_package_journals, journals and work_packages]
  #   ),
  #   other_cte AS ([...with a FROM work_packages...])
  #
  # SELECT * from work_packages

  def build_arel(aliases = nil)
    substitute_join_tables_in_where_clause(self)

    # Based on the previous modifications, build the algebra object and prepend
    # the journals CTE.
    add_historic_model_cte(super)
  end

  private

  def add_historic_model_cte(arel)
    historic_models_cte = Arel::Nodes::As.new(Arel::Table.new(model.table_name),
                                              historic_models_statement.arel)

    if arel.ast.with
      arel.ast.with.expr.unshift(historic_models_cte)
    else
      arel.ast.with = Arel::Nodes::With.new([historic_models_cte])
    end

    arel
  end

  def historic_models_statement
    relation = Journal
                 .joins(historic_models_data_journals_join)
                 .joins(historic_models_original_models_join)
                 .select(historic_models_selects)

    add_timestamp_condition(relation)
  end

  def historic_models_data_journals_join
    <<-SQL.squish
      INNER JOIN #{model.journal_class.table_name}
      ON "#{Journal.table_name}"."data_type" = '#{model.journal_class.name}'
      AND "#{Journal.table_name}"."data_id" = "#{model.journal_class.table_name}"."id"
    SQL
  end

  def historic_models_original_models_join
    <<-SQL.squish
      INNER JOIN #{model.table_name}
      ON #{model.table_name}.id = "#{Journal.table_name}"."journable_id"
    SQL
  end

  def historic_models_selects
    journals = Journal.table_name

    ["#{journals}.journable_id AS id",
     "#{journals}.id AS journal_id",
     "#{model.table_name}.created_at",
     "#{journals}.updated_at",
     "CASE #{timestamp_case_when_statements} END as timestamp",
     *model.journal_class.column_names
           .reject { it == "id" }
           .map { |c| "#{model.journal_class.table_name}.#{c}" },
     *model.column_names_missing_in_journal.map do |missing_column_name|
       "null as #{missing_column_name}"
     end]
  end

  # Additional table joins can appear in the where clause, such as the custom_values table join.
  # We need to substitute the table name ("custom_values") with the journalized table name
  # ("customized_journals") in order to retrieve historic data from the journalized table.

  def substitute_join_tables_in_where_clause(relation)
    relation.where_clause.instance_variable_get(:@predicates).each do |predicate|
      substitute_custom_values_join_in_predicate(predicate)
    end
  end

  # For simplicity's sake we replace the "custom_values" join only when the predicate is a String.
  # This is the way we are receiving the predicate from the `Queries::WorkPackages::Filter::CustomFieldFilter`
  # The joins are defined in the `Queries::WorkPackages::Filter::CustomFieldContext#where_subselect_joins`
  # method. If we ever change that method to use Arel, we will need to implement the substitution
  # for Arel objects as well.
  def substitute_custom_values_join_in_predicate(predicate)
    return unless predicate.is_a? String

    customizable_journals = Journal::CustomizableJournal.table_name
    custom_values = CustomValue.table_name
    models = model.table_name

    predicate.gsub! /JOIN (?<!_)#{custom_values}/,
                    "JOIN #{customizable_journals}"
    predicate.gsub! "JOIN \"#{custom_values}\"",
                    "JOIN \"#{customizable_journals}\""

    # The customizable_journals table has no direct relation to the work_packages table,
    # but it has to the journals table. We join it to the journals table instead.
    predicate.gsub! /#{custom_values}.customized_type = '#{model.name}'\s*AND #{custom_values}.customized_id = #{models}.id/m,
                    "#{customizable_journals}.journal_id = #{models}.journal_id"

    predicate.gsub! "AND #{custom_values}.custom_field_id =",
                    "AND #{customizable_journals}.custom_field_id ="
    # Replace all occurrences of `custom_values.value` within the WHERE clause.
    # This handles operators like "is empty" which generate multiple references:
    # e.g. `WHERE custom_values.value IS NULL OR custom_values.value = ''`
    predicate.gsub!(/WHERE.*#{Regexp.escape(custom_values)}\.value.*/) do |match|
      match.gsub!("#{custom_values}.value", "#{customizable_journals}.value")
    end
  end

  # Add a timestamp condition: Select the work package journals that are the
  # current ones at the given timestamp.
  #
  def add_timestamp_condition(relation)
    timestamp_condition = timestamp.map do |t|
      Journal.where(journable_type: model.name).at_timestamp(t)
    end.reduce(&:or)

    relation.merge(timestamp_condition)
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
                          raise NoMethodError, "Unknown timestamp type: #{timestamp.class}"
                        end

      quoted = ApplicationRecord.connection.quote(timestamp.to_s)
      "WHEN \"#{Journal.table_name}\".\"validity_period\" @> timestamp with time zone '#{comparison_time}' THEN #{quoted}"
    end
      .join(" ")
  end
end
