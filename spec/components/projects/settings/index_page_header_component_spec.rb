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

RSpec.describe Projects::Settings::IndexPageHeaderComponent, type: :component do
  let(:project) { build_stubbed(:project, name: "Important project") }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(project:)) }

  describe "actions" do
    it "always renders the favorite button" do
      expect(rendered_component).to have_link class: "PageHeader-action" do |link|
        expect(link).to have_octicon :star
      end
    end

    context "without project action permissions" do
      it "only renders the responsive favorite menu item" do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 1
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
        end
      end
    end

    context "with project action permissions" do
      let(:user) do
        create(
          :user,
          member_with_permissions: {
            project => %i[add_subprojects copy_projects edit_project archive_project]
          }
        )
      end

      it "renders permitted project actions but not administrator actions", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 5
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Add subproject"
          expect(menu).to have_selector :menuitem, text: "Duplicate"
          expect(menu).to have_selector :menuitem, text: "Make public"
          expect(menu).to have_selector :menuitem, text: "Archive"
          expect(menu).to have_no_selector :menuitem, text: "Set as template"
          expect(menu).to have_no_selector :menuitem, text: "Delete"
        end
      end
    end

    context "as a global administrator" do
      let(:user) { build_stubbed(:admin) }

      it "renders all settings actions in the more menu", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 7
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Add subproject"
          expect(menu).to have_selector :menuitem, text: "Duplicate"
          expect(menu).to have_selector :menuitem, text: "Make public"
          expect(menu).to have_selector :menuitem, text: "Set as template"
          expect(menu).to have_selector :menuitem, text: "Archive"
          expect(menu).to have_selector :menuitem, text: "Delete"
        end
      end
    end
  end
end
