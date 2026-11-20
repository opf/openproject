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

RSpec.describe "Work package custom field types and variants tab", type: :rails_request do
  shared_let(:custom_field) { create(:work_package_custom_field, name: "Severity") }

  shared_let(:form_with_cf) { create(:form_configuration, name: "CF form") }
  shared_let(:form_without_cf) { create(:form_configuration, name: "No-CF form") }

  shared_let(:cf_membership) do
    group = create(:form_configuration_group, form_configuration: form_with_cf)
    create(:form_configuration_attribute, form_configuration: form_with_cf, group:, position: 1, custom_field:)
  end
  shared_let(:plain_membership) do
    group = create(:form_configuration_group, form_configuration: form_without_cf)
    create(:form_configuration_attribute, form_configuration: form_without_cf, group:, position: 1, attribute_key: "assignee")
  end

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }

  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware", form_configuration: form_with_cf) }
  shared_let(:unrelated_variant) do
    create(:type_variant, type: task, variant_name: "Plain", form_configuration: form_without_cf)
  end

  shared_let(:active_project) { create(:project) }
  shared_let(:owned_variant) do
    create(:project_owned_type_variant, type: bug, variant_name: "Owned", project: active_project,
                                        form_configuration: form_with_cf)
  end

  subject(:request) { get types_and_variants_admin_settings_work_package_custom_field_path(custom_field) }

  def row(variant) = "custom-field-type-variant-row-#{variant.id}"

  context "as an admin" do
    current_user { create(:admin) }

    it "shows the types and variants tab" do
      request

      expect(page).to have_link(I18n.t("custom_fields.show.tabs.types_and_variants"),
                                href: types_and_variants_admin_settings_work_package_custom_field_path(custom_field))
    end

    it "lists the variants that show the field" do
      request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(row(hardware))
      expect(response.body).to include("Bug: Hardware")
    end

    it "does not list a variant whose form does not show the field" do
      request

      expect(response.body).not_to include(row(unrelated_variant))
    end

    it "narrows the list with the name filter" do
      filters = [{ name: { operator: "~", values: ["Hardware"] } }].to_json
      get types_and_variants_admin_settings_work_package_custom_field_path(custom_field, filters:)

      expect(response.body).to include(row(hardware))
      expect(response.body).not_to include(row(owned_variant))
    end
  end

  context "as a non-admin" do
    current_user { create(:user) }

    it "is forbidden" do
      request

      expect(response).to have_http_status(:forbidden)
    end
  end
end
