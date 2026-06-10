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

RSpec.describe ResourcePlannerViews::WorkPackageList::SubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] }) }
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user) }

  let(:i18n_ns) { "resource_management.work_package_list.subheader" }

  let(:view) do
    ResourceWorkPackageList.create!(name: "List", parent: resource_planner, project:, principal: user, query:)
  end

  subject(:rendered) do
    render_inline(described_class.new(project:, resource_planner:, view:))
    page
  end

  before { login_as(user) }

  context "with an automatically filtered view" do
    let(:query) do
      Query.new_default(project:, user:).tap do |q|
        q.name = "q"
        q.save!
      end
    end

    it "links the settings action to the edit dialog" do
      expect(rendered).to have_link(
        href: edit_project_resource_planner_view_path(project, resource_planner, view)
      )
    end

    it "shows a plain allocate button (no add-work-package option)" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.allocate"))
      expect(rendered).to have_no_text(I18n.t("#{i18n_ns}.add_work_package"))
    end
  end

  context "with a manually hand-picked view" do
    let(:query) do
      Query.new_default(project:, user:).tap do |q|
        q.name = "q"
        q.add_filter("manual_sort", "ow", [])
        q.sort_criteria = [%w[manual_sorting asc]]
        q.save!
      end
    end

    it "offers both allocate and add-work-package in a dropdown" do
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.allocate"))
      expect(rendered).to have_text(I18n.t("#{i18n_ns}.add_work_package"))
    end

    it "links the add-work-package option to the search dialog" do
      expect(rendered).to have_link(
        href: new_work_package_project_resource_planner_view_path(project, resource_planner, view)
      )
    end
  end
end
