# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Projects::Scopes::AvailableCustomFields do
  shared_let(:project) { create(:project) }

  shared_let(:project_custom_field) { create(:project_custom_field) }

  shared_let(:project_custom_field_mapping) do
    create(:project_custom_field_project_mapping, project:, project_custom_field:)
  end

  describe ".with_available_project_custom_fields" do
    it "returns projects with the given project custom fields" do
      expect(Project.with_available_project_custom_fields([project_custom_field.id]))
        .to contain_exactly(project)
    end
  end

  describe ".without_available_project_custom_fields" do
    it "returns projects without the given project custom fields" do
      expect(Project.without_available_project_custom_fields([project_custom_field.id])).to be_empty
    end
  end

  describe ".with_available_custom_fields / .without_available_custom_fields" do
    shared_let(:type) { create(:type) }
    shared_let(:work_package_custom_field) { create(:integer_wp_custom_field) }
    shared_let(:other_field) { create(:integer_wp_custom_field) }

    shared_let(:using_project) { create(:project, types: [type]) }
    shared_let(:bystander) { create(:project, no_types: true) }

    before do
      base = type.default_variant
      base.custom_field_ids = [work_package_custom_field.id]
      base.attribute_groups = [["Details", [work_package_custom_field.attribute_name]]]
      base.save!
    end

    it "finds the project whose applied variant shows the field" do
      expect(Project.with_available_custom_fields([work_package_custom_field.id]))
        .to contain_exactly(using_project)
      expect(Project.without_available_custom_fields([work_package_custom_field.id]))
        .to include(bystander)
    end

    it "ignores a field no variant shows" do
      expect(Project.with_available_custom_fields([other_field.id])).to be_empty
    end

    it "follows a variant that inherits the configuration rather than owning it" do
      variant = create(:type_variant, type:, form_configuration_source: type.default_variant)
      ProjectType.find_by(project: using_project, type:).update!(variant:)

      expect(Project.with_available_custom_fields([work_package_custom_field.id]))
        .to contain_exactly(using_project)
    end

    it "drops a project whose variant excludes the field" do
      variant = create(:type_variant, type:,
                                      form_configuration_source: type.default_variant,
                                      form_configuration_excluded_elements: [work_package_custom_field.attribute_name])
      ProjectType.find_by(project: using_project, type:).update!(variant:)

      expect(Project.with_available_custom_fields([work_package_custom_field.id])).to be_empty
      expect(Project.without_available_custom_fields([work_package_custom_field.id]))
        .to include(using_project)
    end

    it "matches nothing for an empty list" do
      expect(Project.with_available_custom_fields([])).to be_empty
    end
  end
end
