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

module TestManagement
  module TestCasesHelper
    def tm_suite_count(suite, suite_counts:, suites: nil)
      direct = suite_counts&.[](suite.id).to_i
      children = suites&.select { |s| s.parent_id == suite.id } || suite.children
      direct + children.sum { |child| tm_suite_count(child, suite_counts:, suites:) }
    end

    def tm_folder_tree_link(project:, suite_id:, label:, count:, selected:, icon: nil)
      link_to project_test_management_test_cases_path(project, suite_id:),
              class: ["tm-folder-item", ("is-selected" if selected)].compact.join(" "),
              "aria-current": (selected ? "page" : nil),
              data: { test_selector: "tm-folder-#{suite_id || 'all'}" } do
        if icon
          concat render(Primer::Beta::Octicon.new(icon:, size: :small, classes: "tm-folder-item--icon",
                                                  "aria-hidden": true))
        end
        concat content_tag(:span, label, class: "tm-folder-item--label")
        concat render(Primer::Beta::Counter.new(count: count.to_i,
                                                scheme: :secondary,
                                                hide_if_zero: false,
                                                classes: "tm-folder-item--count"))
      end
    end

    def tm_render_suite_nodes(project:, suites:, suite_counts:, parent_id: nil, depth: 0, current_suite_id: nil)
      by_parent = suites.group_by(&:parent_id)
      tm_render_suite_level(project, by_parent, parent_id, depth, current_suite_id.to_s, suite_counts:, suites:)
    end

    def tm_render_suite_level(project, by_parent, parent_id, depth, current_suite_id, suite_counts:, suites:) # rubocop:disable Metrics/AbcSize
      Array(by_parent[parent_id]).map do |suite|
        link = tm_folder_tree_link(
          project:,
          suite_id: suite.id,
          label: suite.name,
          count: tm_suite_count(suite, suite_counts:, suites:),
          selected: current_suite_id == suite.id.to_s,
          icon: :"file-directory"
        )
        children = tm_render_suite_level(project, by_parent, suite.id, depth + 1, current_suite_id,
                                         suite_counts:, suites:)

        content_tag(:li, class: "tm-folder-node depth-#{depth}", data: { test_selector: "tm-folder-node-#{suite.id}" }) do
          if children.any?
            content_tag(:details, class: "tm-folder-branch", open: true) do
              content_tag(:summary, class: "tm-folder-row") do
                content_tag(:span, class: "tm-folder-chevron", title: t("test_management.suites.toggle")) do
                  render(Primer::Beta::Octicon.new(icon: :"chevron-right", size: :small, "aria-hidden": true))
                end + link
              end + content_tag(:ul, safe_join(children), class: "tm-folder-children")
            end
          else
            content_tag(:div, class: "tm-folder-row") do
              content_tag(:span, "", class: "tm-folder-chevron tm-folder-chevron--leaf") + link
            end
          end
        end
      end
    end

    def tm_priority_label(priority)
      content_tag(:span, priority.to_s, class: "tm-priority tm-priority-#{priority}")
    end

    def tm_status_label(status)
      content_tag(:span, class: "tm-status tm-status-#{status}") do
        concat content_tag(:span, "", class: "tm-status-dot", "aria-hidden": true)
        concat " #{status}"
      end
    end

    def tm_unknown
      content_tag(:span, "—", class: "color-fg-muted")
    end

    def tm_user_and_time(user, time)
      return tm_unknown if user.nil?

      parts = [link_to_user(user)]
      parts << t("test_management.cases.on_time", time: format_time(time)) if time
      safe_join(parts, " ")
    end
  end
end
