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

RSpec.describe Queries::TypeVariants::Filters::CustomFieldFilter do
  shared_let(:custom_field) { create(:work_package_custom_field) }
  shared_let(:form_with_cf) { create(:form_configuration) }
  shared_let(:form_without_cf) { create(:form_configuration) }

  shared_let(:cf_membership) do
    group = create(:form_configuration_group, form_configuration: form_with_cf)
    create(:form_configuration_attribute, form_configuration: form_with_cf, group:, position: 1, custom_field:)
  end
  shared_let(:plain_membership) do
    group = create(:form_configuration_group, form_configuration: form_without_cf)
    create(:form_configuration_attribute, form_configuration: form_without_cf, group:, position: 1, attribute_key: "assignee")
  end

  shared_let(:variant_type) { create(:type) }
  shared_let(:showing) { create(:type_variant, type: variant_type, form_configuration: form_with_cf) }
  shared_let(:not_showing) { create(:type_variant, type: variant_type, form_configuration: form_without_cf) }
  shared_let(:excluding) do
    create(:type_variant, type: variant_type, form_configuration: form_with_cf,
                          form_configuration_excluded_elements: ["custom_field_#{custom_field.id}"])
  end

  subject(:result) do
    Queries::TypeVariants::TypeVariantQuery.new.where(:custom_field_id, "=", [custom_field.id]).results
  end

  it "includes a variant whose form holds the field" do
    expect(result).to include(showing)
  end

  it "excludes a variant whose form does not hold the field" do
    expect(result).not_to include(not_showing)
  end

  it "excludes a variant that excluded the field from its form" do
    expect(result).not_to include(excluding)
  end

  it "includes a project-owned variant of an active project but not of an archived one" do
    active = create(:project)
    archived = create(:project, active: false)
    owned = create(:project_owned_type_variant, type: variant_type, project: active, form_configuration: form_with_cf)
    archived_owned = create(:project_owned_type_variant, type: variant_type, project: archived,
                                                         form_configuration: form_with_cf)

    expect(result).to include(owned)
    expect(result).not_to include(archived_owned)
  end
end
