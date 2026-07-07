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

module DemoData
  class OverviewSeeder < Seeder
    include CreateAttachments
    include References

    def seed_data!
      print_status "*** Seeding Overview"

      seed_data.each_data("projects") do |project_data|
        overview_data = overview_data(project_data)
        next unless overview_data

        print_status "   -Creating overview for #{project_data.lookup('name')}"

        overview = create_overview(overview_data, project_data)

        overview_data.each("widgets") do |widget_config|
          build_widget(overview, widget_config)
        end

        overview.save!
      end

      add_permission
    end

    def applicable?
      Grids::Overview.count.zero? && demo_projects_exist?
    end

    private

    def demo_projects_exist?
      identifiers = []
      seed_data.each_data("projects") do |project_data|
        identifiers << seed_project_identifier(project_data.lookup("identifier"))
      end

      identifiers.all? { |identifier| Project.exists?(identifier:) }
    end

    def build_widget(overview, widget_config)
      create_attachments!(overview, widget_config)

      widget_options = widget_config["options"]

      text_with_references(overview, widget_options)
      query_id_references(overview, widget_options)

      overview.widgets.build(widget_config.except("attachments"))
    end

    def find_project(project_data)
      Project.find_by!(identifier: seed_project_identifier(project_data.lookup("identifier")))
    end

    def create_overview(overview_data, project_data)
      Grids::Overview.create(
        row_count: overview_data.lookup("row_count"),
        column_count: overview_data.lookup("column_count"),
        project: find_project(project_data)
      )
    end

    def overview_data(project_data)
      project_data.lookup("project-overview")
    end

    def text_with_references(overview, widget_options)
      if widget_options && widget_options["text"]
        widget_options["text"] = with_references(widget_options["text"])
        widget_options["text"] = link_attachments(widget_options["text"], overview.attachments)
      end
    end

    def query_id_references(_overview, widget_options)
      if widget_options && widget_options["queryId"]
        widget_options["queryId"] = with_references(widget_options["queryId"])
      end
    end

    def add_permission
      Role
        .includes(:role_permissions)
        .where(role_permissions: { permission: "edit_project" })
        .each do |role|
        role.add_permission!(:manage_dashboards)
      end
    end
  end
end
