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

RSpec.describe WorkPackages::ProjectAttributesTabComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { create(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:user) { build_stubbed(:admin) }

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(work_package:))
  end

  context "when the project has no custom fields" do
    it "renders nothing" do
      expect(rendered_component.to_html).to be_empty
    end
  end

  context "when the project has custom fields but the user has no permission to view them" do
    let(:user) { build_stubbed(:user) }
    let(:section) { create(:project_custom_field_section) }
    let!(:fields) { create_list(:project_custom_field, 2, project_custom_field_section: section, projects: [project]) }

    it "renders nothing" do
      expect(rendered_component.to_html).to be_empty
    end
  end

  context "when the project has custom fields in multiple sections" do
    let(:section_a) { create(:project_custom_field_section) }
    let(:section_b) { create(:project_custom_field_section) }
    let!(:fields_a) { create_list(:project_custom_field, 2, project_custom_field_section: section_a, projects: [project]) }
    let!(:fields_b) { create_list(:project_custom_field, 1, project_custom_field_section: section_b, projects: [project]) }

    it "renders one section component per custom field section" do
      expect(rendered_component).to have_test_selector("wp-project-attribute-section-#{section_a.id}")
      expect(rendered_component).to have_test_selector("wp-project-attribute-section-#{section_b.id}")
    end
  end
end
