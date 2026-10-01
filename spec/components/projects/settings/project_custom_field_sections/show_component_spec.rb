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

RSpec.describe Projects::Settings::ProjectCustomFieldSections::ShowComponent, type: :component do
  let(:project) { create(:project) }
  let(:section) { create(:project_custom_field_section) }

  subject(:rendered_component) do
    with_request_url("/projects/#{project.id}/settings/project_custom_fields") do
      render_inline(described_class.new(project:, project_custom_field_section: section))
    end
  end

  context "with custom fields" do
    let!(:custom_field) do
      create(:project_custom_field, name: "My field", project_custom_field_section: section, projects: [project])
    end

    before { section.reload }

    it_behaves_like "rendering Box", row_count: 1

    it "renders the section name as the header heading" do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_heading(section.name)
      end
    end

    it "renders a row per custom field" do
      expect(rendered_component).to have_css(".Box-row", text: "My field")
    end

    it "renders the enable-all and disable-all header actions", :aggregate_failures do
      expect(rendered_component).to have_link(
        accessible_name: I18n.t("projects.settings.actions.label_enable_all"),
        href: %r{enable_all_of_section}
      )
      expect(rendered_component).to have_link(
        accessible_name: I18n.t("projects.settings.actions.label_disable_all"),
        href: %r{disable_all_of_section}
      )
      expect(rendered_component).to have_css('a[data-turbo-method="put"]', count: 2)
    end
  end

  context "without custom fields" do
    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("settings.project_attributes.label_no_project_custom_fields")

    it "renders the section name as the header heading" do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_heading(section.name)
      end
    end
  end
end
