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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"

RSpec.describe CostQuery::CustomFieldMixin, :reporting_query_helper do
  minimal_query

  let!(:project) { create(:project_with_types) }
  let!(:user) { create(:admin) }

  describe "#default_join_table" do
    let!(:custom_field) do
      create(:wp_custom_field, :string, name: "Robert'); DROP TABLE Students;-- Roberts")
    end

    before do
      CostQuery::Cache.reset!
      CostQuery::Filter::CustomFieldEntries.all
    end

    after do
      CostQuery::Cache.reset!
      CostQuery::Filter::CustomFieldEntries.reset!
    end

    it "uses field.id in the SQL comment and does not include the field name" do
      query.filter custom_field.attribute_name, operator: "=", value: "test"
      sql = query.sql_statement.to_s

      expect(sql).to include("-- BEGIN Custom Field Join: cf_#{custom_field.id}")
      expect(sql).to include("-- END Custom Field Join: cf_#{custom_field.id}")
      expect(sql).not_to include("DROP TABLE students")
      expect(sql).to include("CAST(value AS varchar)")
    end
  end
end
