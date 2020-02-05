#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CostQuery::SqlStatement < Report::SqlStatement
  COMMON_FIELDS = %w[
    user_id project_id work_package_id rate_id
    comments spent_on created_on updated_on tyear tmonth tweek
    costs overridden_costs type
  ]

  # flag to mark a reporting query consisting of a union of cost and time entries
  attr_accessor :entry_union

  def initialize(table, desc = "")
    super(table, desc)
    @entry_union = false
  end

  # this is a hack to ensure that additional joins added by filters do not result
  # in additional columns being selected.
  def to_s
    select(['entries.*']) if select == ['*'] && group_by.empty? && self.entry_union
    super
  end

  ##
  # Generates SqlStatement that maps time_entries and cost_entries to a common structure.
  #
  # Mapping for direct fields:
  #
  #   Result                    | Time Entires             | Cost entries
  #   --------------------------|--------------------------|--------------------------
  #   id                        | id                       | id
  #   user_id                   | user_id                  | user_id
  #   project_id                | project_id               | project_id
  #   work_package_id           | work_package_id          | work_package_id
  #   rate_id                   | rate_id                  | rate_id
  #   comments                  | comments                 | comments
  #   spent_on                  | spent_on                 | spent_on
  #   created_on                | created_on               | created_on
  #   updated_on                | updated_on               | updated_on
  #   tyear                     | tyear                    | tyear
  #   tmonth                    | tmonth                   | tmonth
  #   tweek                     | tweek                    | tweek
  #   costs                     | costs                    | costs
  #   overridden_costs          | overridden_costs         | overridden_costs
  #   units                     | hours                    | units
  #   activity_id               | activity_id              | -1
  #   cost_type_id              | -1                       | cost_type_id
  #   type                      | "TimeEntry"              | "CostEntry"
  #   count                     | 1                        | 1
  #
  # Also: This _should_ handle joining activities and cost_types, as the logic differs for time_entries
  # and cost_entries.
  #
  # @param [#table_name] model The model to map
  # @return [CostQuery::SqlStatement] Generated statement
  def self.unified_entry(model)
    table = table_name_for model
    new(table).tap do |query|
      query.select COMMON_FIELDS
      query.desc = "Subquery for #{table}"
      query.select({
        count: 1, id: [model, :id], display_costs: 1,
        real_costs: switch("#{table}.overridden_costs IS NULL" => [model, :costs], else: [model, :overridden_costs]),
        week: iso_year_week(:spent_on, model),
        singleton_value: 1 })
      #FIXME: build this subquery from a sql_statement
      query.from "(SELECT *, #{typed :text, model.model_name.to_s} AS type FROM #{table}) AS #{table}"
      send("unify_#{table}", query)
    end
  end

  ##
  # Applies logic for mapping time entries to general entries structure.
  #
  # @param [CostQuery::SqlStatement] query The statement to adjust
  def self.unify_time_entries(query)
    query.select :activity_id, units: :hours, cost_type_id: -1
    query.select cost_type: quoted_label(:caption_labor)
  end

  ##
  # Applies logic for mapping cost entries to general entries structure.
  #
  # @param [CostQuery::SqlStatement] query The statement to adjust
  def self.unify_cost_entries(query)
    query.select :units, :cost_type_id, activity_id: -1
    query.select cost_type: "cost_types.name"
    query.join CostType
  end

  ##
  # Generates a statement based on all entries (i.e. time entries and cost entries) mapped to the general entries structure,
  # and therefore usable by filters and such.
  #
  # @return [CostQuery::SqlStatement] Generated statement
  def self.for_entries
    sql = new unified_entry(TimeEntry).union(unified_entry(CostEntry), "entries")
    sql.entry_union = true
    sql
  end
end
