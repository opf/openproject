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

require "spec_helper"

RSpec.describe ProjectCustomFieldTypeMappings::ToggleService do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:project_custom_field) { create(:project_custom_field) }
  let(:instance) { described_class.new(user:) }

  let(:params) do
    {
      variant_id: variant.id,
      custom_field_id: project_custom_field.id
    }
  end

  context "with admin permissions" do
    let(:user) { create(:admin) }

    it "toggles a project custom field for the type variant" do
      expect(variant.project_custom_fields).to be_empty

      2.times do
        expect(instance.call(**params, value: "1")).to be_success

        expect(variant.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end

      2.times do
        expect(instance.call(**params, value: "0")).to be_success

        expect(variant.reload.project_custom_fields).to be_empty
      end
    end

    it "does not map a work package custom field to the type variant" do
      work_package_custom_field = create(:wp_custom_field)

      result = instance.call(
        variant_id: variant.id,
        custom_field_id: work_package_custom_field.id,
        value: "1"
      )

      expect(result).to be_failure
      expect(ProjectCustomFieldTypeMapping).not_to exist(
        type_variant_id: variant.id,
        custom_field_id: work_package_custom_field.id
      )
    end
  end

  context "without admin permissions" do
    let(:user) { create(:user) }

    it "does not toggle project custom fields for the type variant" do
      expect(instance.call(**params, value: "1")).to be_failure

      expect(variant.reload.project_custom_fields).to be_empty
    end
  end
end
