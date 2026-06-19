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

RSpec.describe Admin::Departments::DetailComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) { render_inline(described_class.new(**args)) }

  context "without a group (global empty state)" do
    let(:args) { { group: nil, child_groups: [] } }

    # The global blank slate carries its own call to action, so it renders as a
    # regular row rather than through the list's empty state slot.
    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t("departments.blankslate.heading"), icon: :people
  end

  context "with an empty department" do
    let(:group) { create(:department) }
    let(:args) { { group:, child_groups: [] } }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t("departments.detail_blankslate.heading"), icon: :people

    it "renders the department name in the breadcrumbs" do
      expect(rendered_component).to have_css("li.breadcrumb-item", text: group.name)
    end

    it "renders the department title and edit action in the header", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_heading(group.name, level: 4)
        expect(header).to have_link(accessible_name: I18n.t(:button_edit), href: edit_admin_department_path(group))
      end
    end
  end

  context "with child departments" do
    let(:group) { create(:department) }
    let(:child) { create(:department, lastname: "Child dept") }
    let(:args) { { group:, child_groups: [child] } }

    it_behaves_like "rendering Box", row_count: 1

    it "renders a row per child department" do
      expect(rendered_component).to have_css(".Box-row", text: "Child dept")
    end
  end
end
