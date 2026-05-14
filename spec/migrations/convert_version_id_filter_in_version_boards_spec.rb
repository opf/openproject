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
require Rails.root.join("db/migrate/20260514120000_convert_version_id_filter_in_version_boards.rb")

RSpec.describe ConvertVersionIdFilterInVersionBoards, type: :model do
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:project) { create(:project) }
  let(:version) { create(:version, project:) }

  def build_query(filter_name)
    q = Query.new_default(project:, user: User.system, name: "Q #{filter_name}")
    q.add_filter(filter_name.to_s, "=", [version.id.to_s])
    q.save!(validate: false)
    q
  end

  def build_grid(attribute, query, widget_filter_key: nil)
    g = Boards::Grid.create!(
      name: "#{attribute} board",
      project:,
      row_count: 1,
      column_count: 1,
      options: { "type" => "action", "attribute" => attribute }
    )
    g.widgets.create!(
      start_row: 1,
      start_column: 1,
      end_row: 2,
      end_column: 2,
      identifier: "work_package_query",
      options: {
        "queryId" => query.id,
        "filters" => [{ widget_filter_key => { operator: "=", values: [version.id.to_s] } }]
      }
    )
    g
  end

  it "rewrites :version_id to :target_version_id on a version board query" do
    query = build_query(:version_id)
    build_grid("version", query, widget_filter_key: :version_id)

    run_migration

    filter_names = query.reload.filters.map(&:name)
    expect(filter_names).to include(:target_version_id)
    expect(filter_names).not_to include(:version_id)
    target = query.filters.find { |f| f.name == :target_version_id }
    expect(target.values).to eq([version.id.to_s])
  end

  it "rewrites the widget options['filters'] snapshot, preserving the symbol key" do
    query = build_query(:version_id)
    grid = build_grid("version", query, widget_filter_key: :version_id)

    run_migration

    filter_hash = grid.widgets.reload.first.options["filters"].first
    expect(filter_hash.keys).to eq([:target_version_id])
    expect(filter_hash.values.first[:values] || filter_hash.values.first["values"])
      .to eq([version.id.to_s])
  end

  it "leaves non-version action boards (e.g. status) untouched" do
    query = build_query(:version_id)
    grid = Boards::Grid.create!(
      name: "Status board",
      project:,
      row_count: 1,
      column_count: 1,
      options: { "type" => "action", "attribute" => "status" }
    )
    widget = grid.widgets.create!(
      start_row: 1, start_column: 1, end_row: 2, end_column: 2,
      identifier: "work_package_query",
      options: {
        "queryId" => query.id,
        "filters" => [{ version_id: { operator: "=", values: [version.id.to_s] } }]
      }
    )
    original_options = widget.options

    run_migration

    filter_names = query.reload.filters.map(&:name)
    expect(filter_names).to include(:version_id)
    expect(filter_names).not_to include(:target_version_id)
    expect(widget.reload.options).to eq(original_options)
  end

  it "is a no-op for a version board already on :target_version_id" do
    query = build_query(:target_version_id)
    grid = build_grid("version", query, widget_filter_key: :target_version_id)
    raw_filters_before = ActiveRecord::Base.connection.select_value(
      "SELECT filters FROM queries WHERE id = #{query.id}"
    )
    original_widget_options = grid.widgets.first.options

    run_migration

    raw_filters_after = ActiveRecord::Base.connection.select_value(
      "SELECT filters FROM queries WHERE id = #{query.id}"
    )
    expect(raw_filters_after).to eq(raw_filters_before)
    expect(grid.widgets.reload.first.options).to eq(original_widget_options)
  end

  it "leaves standalone :version_id queries (not referenced by a version board) untouched" do
    standalone = build_query(:version_id)

    run_migration

    filter_names = standalone.reload.filters.map(&:name)
    expect(filter_names).to include(:version_id)
    expect(filter_names).not_to include(:target_version_id)
  end
end
