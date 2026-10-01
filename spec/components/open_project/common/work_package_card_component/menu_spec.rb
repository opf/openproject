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

RSpec.describe OpenProject::Common::WorkPackageCardComponent::Menu, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:user) { create(:admin) }
  current_user { user }

  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:menu_button_id) { "work_package_#{work_package.id}_menu-button" }
  let(:src) { menu_project_backlogs_work_package_path(project, work_package) }
  let(:system_arguments) { {} }

  subject(:rendered_component) do
    render_inline(described_class.new(work_package:, src:, **system_arguments))
  end

  it "renders an action-menu element" do
    expect(rendered_component).to have_element :"action-menu"
  end

  it "renders the kebab show button with the standard accessible label" do
    expect(rendered_component).to have_button(
      menu_button_id,
      accessible_name: I18n.t("open_project.common.work_package_card_component.menu.label_actions")
    )
  end

  it "uses a stable menu id derived from the work package" do
    expect(rendered_component).to have_button(menu_button_id)
  end

  it "loads the menu list deferred via include-fragment with the given src" do
    expect(rendered_component).to have_element "include-fragment",
                                               src:
  end

  it "applies the hide-when-print class to the menu wrapper" do
    expect(rendered_component).to have_element :"action-menu", class: "hide-when-print"
  end

  context "when no src is provided" do
    let(:src) { nil }

    subject(:rendered_component) do
      render_inline(described_class.new(work_package:, src:)) do |menu|
        menu.with_item(label: "Edit", href: "/edit")
      end
    end

    it "renders inline menu items" do
      expect(rendered_component).to have_link "Edit", href: "/edit"
    end

    it "does not render a deferred include-fragment" do
      expect(rendered_component).to have_no_element "include-fragment"
    end
  end

  context "when a custom menu id is provided" do
    let(:system_arguments) { { menu_id: "custom-card-menu" } }

    it "uses the provided menu id" do
      expect(rendered_component).to have_button "custom-card-menu-button"
    end
  end
end
