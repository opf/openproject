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

require "rails_helper"

RSpec.describe ResourcePlannerViews::WorkPackageList::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] }) }
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:work_packages) { create_list(:work_package, 2, project:) }

  let(:i18n_ns) { "resource_management.work_package_list.context_menu" }
  let(:view) do
    ResourceWorkPackageList.create!(name: "List", parent: resource_planner, project:, principal: user, query:)
  end
  let(:allocations) { {} }
  let(:table) do
    ResourcePlannerViews::WorkPackageList::TableComponent.new(
      rows: work_packages, view:, project:, resource_planner:, allocations:
    )
  end

  def manual_query
    Query.new_default(project:, user:).tap do |q|
      q.name = "q"
      q.add_filter("manual_sort", "ow", [])
      q.sort_criteria = [%w[manual_sorting asc]]
      q.save!
    end
  end

  def automatic_query
    Query.new_default(project:, user:).tap do |q|
      q.name = "q"
      q.save!
    end
  end

  subject(:rendered) do
    render_inline(described_class.new(row: work_packages.first, table:))
    page
  end

  before { login_as(user) }

  context "with an automatically filtered view" do
    let(:query) { automatic_query }

    it "does not offer the manual-list actions" do
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.move"))
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.remove"))
    end

    it "offers the filter-criteria shortcut instead" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.add_filter_criteria"))
    end

    it "renders no drag handle" do
      expect(rendered).to have_no_css(".DragHandle")
    end
  end

  context "with the edit-work-packages permission" do
    shared_let(:editor) do
      create(:user,
             member_with_permissions: {
               project => %i[view_resource_planners view_work_packages edit_work_packages]
             })
    end
    let(:query) { automatic_query }

    before { login_as(editor) }

    it "offers the edit total work action linking to the progress dialog" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.edit_total_work"))
      expect(rendered).to have_css(
        "a[data-controller='async-dialog']" \
        "[href='#{edit_project_resource_planner_view_work_package_progress_path(
          project, resource_planner, view, work_packages.first
        )}']"
      )
    end
  end

  context "without the edit-work-packages permission" do
    let(:query) { automatic_query }

    it "hides the edit total work action" do
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.edit_total_work"))
    end
  end

  context "with members allocated to the work package" do
    let(:query) { automatic_query }
    let(:member) { create(:user, firstname: "Michael", lastname: "Johnson") }
    let(:allocation) { create(:resource_allocation, entity: work_packages.first, principal: member) }
    let(:allocations) { { work_packages.first.id => [allocation] } }

    it "renders the allocated members' avatar stack instead of the placeholder" do
      expect(rendered).to have_css("avatar-fallback[data-unique-id='#{member.id}']")
    end
  end

  context "with a manually hand-picked view" do
    let(:query) { manual_query }

    before do
      work_packages.each_with_index do |wp, i|
        view.query.ordered_work_packages.create!(work_package: wp, position: i + 1)
      end
    end

    it "offers move and remove" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.move"))
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.remove"))
    end

    it "renders a drag handle" do
      expect(rendered).to have_css(".DragHandle")
    end

    it "confirms before removing" do
      expect(rendered).to have_css("[data-turbo-confirm='#{I18n.t("#{i18n_ns}.remove_confirmation")}']")
    end

    it "omits the up/top moves for the first row" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.move_down"))
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.move_to_bottom"))
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.move_up"))
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.move_to_top"))
    end
  end

  context "with a single hand-picked row" do
    let(:query) { manual_query }
    let(:table) do
      ResourcePlannerViews::WorkPackageList::TableComponent.new(
        rows: [work_packages.first], view:, project:, resource_planner:, allocations:
      )
    end

    it "disables the move entry, since it cannot be moved" do
      expect(rendered).to have_css(".ActionListItem--disabled", text: "Move", visible: :all)
    end
  end
end
