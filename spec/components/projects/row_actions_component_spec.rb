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

RSpec.describe Projects::RowActionsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project, name: "My Project No. 1", identifier: "myproject_no_1") }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(project:, params: {}))
  end

  describe "menu items" do
    context "when the user has no project permissions" do
      it "renders only the favorite item", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, count: 1
        expect(rendered_component).to have_selector :menuitem, text: "Add to favorites"
      end
    end

    context "when the user is an admin" do
      let(:user) { build_stubbed(:admin) }

      it "renders all applicable items", :aggregate_failures do
        expect(rendered_component).to have_selector :menuitem, count: 7
        expect(rendered_component).to have_selector :menuitem, text: "New subproject"
        expect(rendered_component).to have_selector :menuitem, text: "Project settings"
        expect(rendered_component).to have_selector :menuitem, text: "Project activity"
        expect(rendered_component).to have_selector :menuitem, text: "Add to favorites"
        expect(rendered_component).to have_selector :menuitem, text: "Archive"
        expect(rendered_component).to have_selector :menuitem, text: "Copy"
        expect(rendered_component).to have_selector :menuitem, text: "Delete" do |link|
          expect(link[:href]).to eq confirm_destroy_project_path(project)
          expect(link[:"data-turbo-stream"]).to eq "true"
        end
      end
    end
  end

  describe ".menu_id" do
    it "returns a stable id based on the project" do
      expect(described_class.menu_id(project)).to eq "project-#{project.id}-action-menu"
    end
  end
end
