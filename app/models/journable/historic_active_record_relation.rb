#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class Journable::HistoricActiveRecordRelation < ActiveRecord::Relation
  # See: https://github.com/opf/openproject/pull/11243

  attr_accessor :timestamp

  include ActiveRecord::Delegation::ClassSpecificRelation

  def initialize(relation, timestamp:)
    raise ArgumentError, "Expected ActiveRecord::Relation" unless relation.kind_of? ActiveRecord::Relation
    relation.instance_variables.each do |key|
      self.instance_variable_set key, relation.instance_variable_get(key)
    end

    self.timestamp = timestamp
    self.readonly!
    self.instance_variable_set :@table, model.journal_class.arel_table

    return self
  end

  # We need to patch the `pluck` method of an active-record relation that
  # queries historic data (i.e. journal data). Otherwise, `pluck(:id)`
  # would return the `id` of the journal table rather than the `id` of the
  # journable table, which would be expected from the syntax:
  #
  #     WorkPackage.where(assigned_to_id: 123).at_timestamp(1.year.ago).pluck(:id)
  #
  def pluck(*column_names)
    column_names.map! { |column_name| column_name == :id ? 'journals.journable_id' : column_name }
    arel
    super
  end

  # Patch the arel object, which is used to construct the sql query, in order
  # to modify the query to search for historic data.
  #
  alias_method :original_build_arel, :build_arel
  def call_original_build_arel
    original_build_arel
  end
  def build_arel(aliases = nil)
    relation = self

    # Switch the database table from `work_packages` to `work_package_journals`.
    relation.instance_variable_set :@table, model.journal_class.arel_table

    # Modify there where clauses such that the work-packages table is substituted
    # with the work-package-journals table.
    relation.where_clause.instance_variable_get(:@predicates).each do |predicate|
      if predicate.left.relation == self.arel_table
        predicate.left.relation = self.journal_class.arel_table
      end
    end

    # Add a timestamp condition: Select the work package journals that are the
    # current ones at the given timestamp.
    relation = relation \
        .joins("INNER JOIN \"journals\" ON \"journals\".\"data_type\" = '#{model.journal_class.name}' AND \"journals\".\"data_id\" = \"#{model.journal_class.table_name}\".\"id\"") \
        .merge(Journal.at_timestamp(timestamp))

    # Join the journables table itself because we need to take the 'created_at' attribute from that.
    relation = relation \
        .joins("INNER JOIN (SELECT id, created_at FROM \"#{model.table_name}\") AS journables ON \"journables\".\"id\" = \"journals\".\"journable_id\"")

    # At this point, the id is wrong. The sql statement returns the id of the work package journal,
    # but active record instantiates this into the WorkPackage model. Because the resulting model
    # will be a WorkPackage, we need a work-package id, which we take from the journals table.
    if relation.select_values.count == 0
      relation = relation.select("'#{timestamp}' as timestamp, #{model.journal_class.table_name}.*, journals.journable_id as id, journables.created_at as created_at, journals.created_at as updated_at")
    end

    # Based on the previous modifications, build the algebra object.
    @arel = relation.call_original_build_arel

    # Modify order clauses to use the work-pacakge-journals table.
    @arel.instance_variable_get(:@ast).instance_variable_get(:@orders).each do |order_clause|
      if order_clause.expr.relation == model.arel_table
        order_clause.expr.relation = model.journal_class.arel_table
      end
    end

    # Move the journals join to the beginning because other joins depend on it.
    @arel.instance_variable_get(:@ast).instance_variable_get(:@cores).each do |core|
      array_of_joins = core.instance_variable_get(:@source).right
      if journals_join_index = array_of_joins.find_index { |join| join.kind_of?(Arel::Nodes::StringJoin) && join.left.include?("INNER JOIN \"journals\" ON \"journals\".\"data_type\"") }
        journals_join = array_of_joins[journals_join_index]
        array_of_joins.delete_at(journals_join_index)
        array_of_joins.insert(0, journals_join)
      end
    end

    # Modify the joins to point to the journable_id.
    @arel.instance_variable_get(:@ast).instance_variable_get(:@cores).each do |core|
      core.instance_variable_get(:@source).right.each do |node|
        if node.kind_of?(Arel::Nodes::Join) and node.right.kind_of?(Arel::Nodes::On)
          [node.right.expr.left, node.right.expr.right].each do |attribute|
            if (attribute.relation == journal_class.arel_table) and (attribute.name == "id")
              attribute.relation = Journal.arel_table
              attribute.name = "journable_id"
            end
          end
        end
      end
    end

    return @arel
  end

  # TODO: Add tests when having several work packages

end