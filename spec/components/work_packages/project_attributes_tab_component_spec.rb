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
  let(:type) { create(:type) }
  let(:work_package) { build_stubbed(:work_package, project:, type:) }
  let(:user) { build_stubbed(:admin) }

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(work_package:))
  end

  def create_field_for(wp_type, section:)
    create(:project_custom_field, project_custom_field_section: section, projects: [project]).tap do |f|
      wp_type.project_custom_fields << f
    end
  end

  context "when the project has no custom fields" do
    it "renders nothing" do
      expect(rendered_component.to_html).to be_empty
    end
  end

  context "when the project has custom fields mapped to the type but the user has no permission to view them" do
    let(:user) { build_stubbed(:user) }
    let(:section) { create(:project_custom_field_section) }
    let!(:fields) { Array.new(2) { create_field_for(type, section:) } }

    it "renders nothing" do
      expect(rendered_component.to_html).to be_empty
    end
  end

  context "when the project has custom fields in multiple sections mapped to the type" do
    let(:section_a) { create(:project_custom_field_section) }
    let(:section_b) { create(:project_custom_field_section) }
    let!(:fields_a) { Array.new(2) { create_field_for(type, section: section_a) } }
    let!(:fields_b) { [create_field_for(type, section: section_b)] }

    it "renders one section component per custom field section" do
      expect(rendered_component).to have_test_selector("wp-project-attribute-section-#{section_a.id}")
      expect(rendered_component).to have_test_selector("wp-project-attribute-section-#{section_b.id}")
    end
  end

  context "when the project has custom fields with type mappings" do
    let(:section) { create(:project_custom_field_section) }
    let(:other_type) { create(:type) }
    let!(:field_for_type) { create_field_for(type, section:) }
    let!(:field_for_other_type) { create_field_for(other_type, section:) }
    let!(:field_without_mapping) do
      create(:project_custom_field, project_custom_field_section: section, projects: [project])
    end

    it "only renders fields mapped to the work package type" do
      expect(rendered_component).to have_test_selector("wp-project-attribute-section-#{section.id}")
      expect(rendered_component).to have_text(field_for_type.name)
      expect(rendered_component).to have_no_text(field_for_other_type.name)
      expect(rendered_component).to have_no_text(field_without_mapping.name)
    end
  end
end
