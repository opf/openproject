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

RSpec.describe Hotkeys::FallbackLinksComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) do
    create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking wiki]).reload
  end
  let(:permissions) { %i[add_work_packages view_wiki_pages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  def render_component(project:, user: self.user, can_add_work_packages: true)
    render_inline(described_class.new(project:, user:, can_add_work_packages:))
  end

  describe "new work package link" do
    it "links to the project form" do
      render_component(project:)

      expect(page).to have_link("New work package", href: new_project_work_packages_path(project))
      expect(page).to have_element(
        :a, accesskey: "2", "data-hotkey": "n w p", "data-hotkey-fallback": true
      )
    end

    it "stays outside the hidden box, visually hidden and out of the tab order" do
      render_component(project:)

      expect(page).to have_element(:a, accesskey: "2", class: "sr-only", tabindex: "-1", visible: :visible)
    end

    it "links to the global form without a project" do
      render_component(project: nil)

      expect(page).to have_link("New work package", href: new_work_package_path)
      expect(page).to have_element(:a, accesskey: "2")
    end

    it "is absent when the user may not add work packages" do
      render_component(project:, can_add_work_packages: false)

      expect(page).to have_no_link("New work package", visible: :all)
    end
  end

  describe "wiki start link" do
    it "links to the project wiki start page with the fallback marker" do
      render_component(project:)

      expect(page).to have_element(
        :a, "data-hotkey": "g w i", "data-hotkey-fallback": true, visible: :hidden
      )
    end

    it "is absent when the wiki module is disabled" do
      project.wiki.update!(enabled: false)

      render_component(project: project.reload)

      expect(page).to have_no_element(:a, "data-hotkey": "g w i", visible: :all)
    end

    it "is absent without view_wiki_pages" do
      user = create(:user, member_with_permissions: { project => %i[add_work_packages] })

      render_component(project:, user:)

      expect(page).to have_no_element(:a, "data-hotkey": "g w i", visible: :all)
    end

    it "is absent without a project" do
      render_component(project: nil)

      expect(page).to have_no_element(:a, "data-hotkey": "g w i", visible: :all)
    end
  end

  describe "shortcuts help link" do
    it "opens the help page in a new window" do
      render_component(project:)

      expect(page).to have_link(
        "Keyboard shortcuts",
        href: keyboard_shortcuts_help_path,
        target: "_blank",
        visible: :hidden
      )
      expect(page).to have_element(:a, "data-hotkey": "?,Shift+?", visible: :hidden)
    end
  end

  describe "list navigation buttons" do
    it "renders next and previous buttons bound to list item actions" do
      render_component(project:)

      expect(page).to have_button("Next list item", visible: :hidden)
      expect(page).to have_button("Previous list item", visible: :hidden)
      expect(page).to have_element(:button, "data-hotkey-action": "next-list-item", visible: :hidden)
      expect(page).to have_element(:button, "data-hotkey-action": "previous-list-item", visible: :hidden)
    end

    it "binds j to the next and k to the previous item" do
      render_component(project:)

      expect(page).to have_element(:button, "data-hotkey": "j", "data-hotkey-action": "next-list-item", visible: :hidden)
      expect(page).to have_element(:button, "data-hotkey": "k", "data-hotkey-action": "previous-list-item", visible: :hidden)
    end

    it "lets j and k repeat while held" do
      render_component(project:)

      expect(page).to have_element(:button, "data-hotkey": "j", "data-hotkey-repeat": true, visible: :hidden)
      expect(page).to have_element(:button, "data-hotkey": "k", "data-hotkey-repeat": true, visible: :hidden)
    end
  end
end
