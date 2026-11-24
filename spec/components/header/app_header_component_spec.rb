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

require "rails_helper"

RSpec.describe Header::AppHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] }) }

  current_user { user }

  def render_component(project: self.project, user: self.user)
    render_inline(described_class.new(project:, user:))
  end

  it "renders the app header with the hotkey fallback links" do
    render_component

    expect(page).to have_element(:header, class: "op-app-header")
    expect(page).to have_link("New work package", href: new_project_work_packages_path(project))
  end

  describe "new work package fallback link" do
    it "is absent when the work package module is disabled" do
      project.update!(enabled_module_names: %w[wiki])

      render_component

      expect(page).to have_no_link("New work package", visible: :all)
    end

    it "is absent without the add permission" do
      render_component(user: create(:user, member_with_permissions: { project => %i[view_work_packages] }))

      expect(page).to have_no_link("New work package", visible: :all)
    end

    it "links to the global form outside a project when the user may add work packages somewhere" do
      render_component(project: nil)

      expect(page).to have_link("New work package", href: new_work_package_path)
    end

    it "treats an unsaved project as no project" do
      render_component(project: Project.new)

      expect(page).to have_link("New work package", href: new_work_package_path)
    end

    it "is absent outside a project when the user may not add work packages anywhere" do
      render_component(project: nil, user: create(:user))

      expect(page).to have_no_link("New work package", visible: :all)
    end
  end
end
