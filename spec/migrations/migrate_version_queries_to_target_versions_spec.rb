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

require "spec_helper"
require Rails.root.join("db/migrate/20260721100000_migrate_version_queries_to_target_versions.rb")

RSpec.describe MigrateVersionQueriesToTargetVersions, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:project) { create(:project) }
  let(:version) { create(:version, project:) }

  # Bare accessor to read the raw serialized strings written by the migration.
  let(:raw_query_class) do
    Class.new(ActiveRecord::Base) { self.table_name = "queries" }
  end

  describe "queries table" do
    let!(:query) do
      create(:query, project:, user: create(:user)).tap do |q|
        q.add_filter("version_id", "=", [version.id.to_s])
        q.column_names = %i[id version subject]
        q.sort_criteria = [["version", "asc"]]
        q.group_by = "version"
        q.save(validate: false)
      end
    end

    it "rewrites the version_id filter to target_version_id, keeping operator and values" do
      migrate

      filter = query.reload.filters.detect { |f| f.name == :target_version_id }
      expect(filter).to be_present
      expect(query.filters.map(&:name)).not_to include(:version_id)
      expect(filter.operator).to eq("=")
      expect(filter.values).to eq([version.id.to_s])
    end

    it "rewrites the version column to target_versions, preserving order and siblings" do
      migrate

      expect(query.reload.column_names).to eq(%i[id target_versions subject])
    end

    it "rewrites the version sort criterion to target_versions" do
      migrate

      expect(query.reload.sort_criteria).to eq([["target_versions", "asc"]])
    end

    it "rewrites the version group_by to target_versions" do
      migrate

      expect(query.reload.group_by).to eq("target_versions")
    end

    it "leaves queries without version references untouched" do
      other = create(:query, project:, user: create(:user)).tap do |q|
        q.add_filter("status_id", "o", [])
        q.column_names = %i[id subject]
        q.save(validate: false)
      end
      before = raw_query_class.find(other.id).attributes.slice("filters", "column_names", "sort_criteria", "group_by")

      migrate

      after = raw_query_class.find(other.id).attributes.slice("filters", "column_names", "sort_criteria", "group_by")
      expect(after).to eq(before)
    end

    it "is idempotent" do
      migrate
      first = raw_query_class.find(query.id).attributes.slice("filters", "column_names", "sort_criteria", "group_by")

      ActiveRecord::Migration.suppress_messages { described_class.new.up }
      second = raw_query_class.find(query.id).attributes.slice("filters", "column_names", "sort_criteria", "group_by")

      expect(second).to eq(first)
    end
  end

  describe "board widget filters in grid_widgets.options" do
    let(:grid) { create(:grid) }

    def create_widget(options)
      widget = Grids::Widget.new(
        grid:,
        identifier: "work_package_query",
        start_row: 1, end_row: 2, start_column: 1, end_column: 2,
        options:
      )
      widget.save(validate: false)
      widget
    end

    it "rewrites the symbol :version_id key written by the backend board create service" do
      widget = create_widget("queryId" => 1, "filters" => [{ version_id: { operator: "=", values: [version.id.to_s] } }])

      migrate

      filters = widget.reload.options["filters"]
      expect(filters.first.keys).to contain_exactly(:target_version_id)
      expect(filters.first[:target_version_id]).to eq(operator: "=", values: [version.id.to_s])
    end

    it "rewrites the string version key written when a list is added via the frontend" do
      widget = create_widget("queryId" => 1, "filters" => [{ "version" => { "operator" => "=", "values" => [version.id.to_s] } }])

      migrate

      expect(widget.reload.options["filters"].first.keys).to contain_exactly("targetVersion")
    end

    it "leaves an inline queryProps blob untouched" do
      props = JSON.dump("f" => [{ "n" => "version", "o" => "=", "v" => [version.id.to_s] }], "c" => %w[id version])
      widget = create_widget("queryProps" => props)

      migrate

      expect(widget.reload.options["queryProps"]).to eq(props)
    end

    it "leaves unrelated widget options untouched" do
      widget = create_widget("queryId" => 1, "filters" => [{ status_id: { operator: "o", values: [] } }])
      before = widget.reload.options

      migrate

      expect(widget.reload.options).to eq(before)
    end
  end
end
