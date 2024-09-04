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

class MyProjectPageToGrid < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/ApplicationRecord
  class MyPageEntry < ActiveRecord::Base
    self.table_name = "my_projects_overviews"

    serialize :top
    serialize :left
    serialize :right
  end
  # rubocop:enable Rails/ApplicationRecord

  def up
    return unless applicable?

    recreate_my_page_entries
    remove_my_page_table
    add_permission
  end

  def down
    # down migration will loose data
    Grids::Overview.destroy_all

    create_table :my_projects_overviews, id: :integer do |t|
      t.integer "project_id", default: 0, null: false
      t.text "left", null: false
      t.text "right", null: false
      t.text "top", null: false
      t.text "hidden", null: false
      t.datetime "created_on", null: false
    end
  end

  def recreate_my_page_entries
    migratable_entries.in_batches(of: 200).each do |entries|
      entries.each do |entry|
        grid = create_grid(entry)
        move_attachments(entry, grid)
      end
    end
  end

  def remove_my_page_table
    drop_table :my_projects_overviews
  end

  def add_permission
    Role
      .includes(:role_permissions)
      .where(role_permissions: { permission: "edit_project" })
      .each do |role|
      role.add_permission!(:manage_overview)
    end
  end

  def create_grid(entry)
    grid = Grids::Overview.new project_id: entry.project_id, column_count: 2, created_at: entry.created_on

    %i[top left right].each do |area|
      entry.send(area).each do |widget|
        build_widget(grid, widget, area)
      end
    end

    grid.row_count = grid.widgets.map(&:end_row).max || 1

    grid.save!
    grid
  end

  def move_attachments(entry, grid)
    execute <<~SQL.squish
      UPDATE attachments
      SET container_type = 'Grids::Grid', container_id = #{grid.id}
      WHERE container_type = 'MyProjectsOverview'
      AND container_id = #{entry.id}
    SQL
  end

  def build_widget(grid, widget_config, position)
    method = case widget_config
             when Array
               :build_custom_text_widget
             when "project_details"
               :build_project_details_widget
             when "work_packages_assigned_to_me",
                  "work_packages_reported_by_me",
                  "work_packages_responsible_for",
                  "work_packages_watched"
               :build_wp_table_widget
             else
               :build_default_widget
             end

    send(method, grid, widget_config, position)
  end

  def build_custom_text_widget(grid, widget_config, position)
    build_widget_with_options(grid, "custom_text", position) do |options|
      name = widget_config[1].presence || "Text"

      options[:name] = name
      options[:text] = widget_config[2]
    end
  end

  def build_project_details_widget(grid, _identifier, position)
    build_default_widget(grid, "subprojects", position)
    build_default_widget(grid, "project_details", position)
  end

  def build_wp_table_widget(grid, identifier, position)
    query = query(grid, identifier)

    build_widget_with_options(grid, identifier, position) do |options|
      options[:name] = wp_table_widget_name(identifier)
      options[:queryId] = query.id.to_s
    end
  end

  def build_default_widget(grid, identifier, position)
    build_widget_with_options(grid, identifier, position)
  end

  def build_widget_with_options(grid, identifier, position)
    position_args = next_position(grid, position)

    new_identifier = new_name(identifier)

    options = {
      name: I18n.t("js.grid.widgets.#{new_identifier}.title")
    }

    yield options if block_given?

    grid.widgets.build position_args.merge(options:, identifier: new_identifier)
  end

  def new_name(name)
    {
      news_latest: "news",
      work_package_tracking: "work_packages_overview",
      spent_time: "time_entries_list",
      work_packages_assigned_to_me: "work_packages_table",
      work_packages_reported_by_me: "work_packages_table",
      work_packages_responsible_for: "work_packages_table",
      work_packages_watched: "work_packages_table"
    }.with_indifferent_access[name] || name
  end

  def next_position(grid, position)
    send(:"next_#{position}_position", grid)
  end

  def next_top_position(grid)
    start_row = grid.widgets.map(&:end_row).max || 1

    {
      start_row:,
      end_row: start_row + 1,
      start_column: 1,
      end_column: 3
    }
  end

  def next_left_position(grid)
    start_row = grid.widgets.select { |w| w.start_column == 1 }.map(&:end_row).max || 1

    {
      start_row:,
      end_row: start_row + 1,
      start_column: 1,
      end_column: 2
    }
  end

  def next_right_position(grid)
    start_row = grid.widgets.select { |w| w.end_column == 3 }.map(&:end_row).max || 1

    {
      start_row:,
      end_row: start_row + 1,
      start_column: 2,
      end_column: 3
    }
  end

  def applicable?
    ActiveRecord::Base.connection.table_exists?("my_projects_overviews")
  end

  def attachments(id)
    Attachment.where(container_type: "MyProjectsOverview", container_id: id)
  end

  def new_default_query(attributes = nil)
    Query.new(attributes).tap do |query|
      query.add_default_filter
      query.set_default_sort
      query.show_hierarchies = true
    end
  end

  def query(grid, identifier)
    query = new_default_query name: "_",
                              is_public: true,
                              hidden: true,
                              project_id: grid.project_id,
                              user: query_user(grid)

    query.add_filter(filter_name(identifier), "=", [::Queries::Filters::MeValue::KEY])
    query.column_names = %w(id type subject)

    User.execute_as(query.user) do
      query.save(validate: false)
    end

    query
  end

  def migratable_entries
    MyPageEntry
      .where("project_id IN (SELECT id from projects)")
  end

  def filter_name(identifier)
    case identifier
    when "work_packages_assigned_to_me"
      "assigned_to_id"
    when "work_packages_reported_by_me"
      "author_id"
    when "work_packages_responsible_for"
      "responsible_id"
    when "work_packages_watched"
      "watcher_id"
    end
  end

  def wp_table_widget_name(identifier)
    new_identifier = case identifier
                     when "work_packages_assigned_to_me"
                       "work_packages_assigned"
                     when "work_packages_reported_by_me"
                       "work_packages_created"
                     when "work_packages_responsible_for"
                       "work_packages_accountable"
                     when "work_packages_watched"
                       "work_packages_watched"
                     end

    I18n.t("js.grid.widgets.#{new_identifier}.title")
  end

  def query_user(grid)
    User.includes(:members).where(members: { project_id: grid.project_id }).first || User.active.admin.first
  end
end
