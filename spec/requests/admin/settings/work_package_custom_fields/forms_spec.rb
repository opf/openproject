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

RSpec.describe "Work package custom field forms tab", type: :rails_request do
  shared_let(:custom_field) { create(:work_package_custom_field, name: "Severity") }

  shared_let(:hardware_form) { create(:form_configuration, name: "Hardware form", description: "For hardware") }
  shared_let(:software_form) { create(:form_configuration, name: "Software form") }
  shared_let(:unrelated_form) { create(:form_configuration, name: "Unrelated form") }

  before_all do
    [hardware_form, software_form].each do |form|
      group = create(:form_configuration_group, form_configuration: form)
      create(:form_configuration_attribute, form_configuration: form, group:, position: 1, custom_field:)
    end

    group = create(:form_configuration_group, form_configuration: unrelated_form)
    create(:form_configuration_attribute, form_configuration: unrelated_form, group:, position: 1, attribute_key: "assignee")
  end

  subject(:request) { get forms_admin_settings_work_package_custom_field_path(custom_field) }

  context "as an admin" do
    current_user { create(:admin) }

    it "shows the forms tab" do
      request

      expect(page).to have_link(I18n.t("custom_fields.show.tabs.forms"),
                                href: forms_admin_settings_work_package_custom_field_path(custom_field))
    end

    it "lists only the forms that include the custom field, with their description" do
      request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hardware form", "Software form", "For hardware")
      expect(response.body).not_to include("Unrelated form")
    end

    it "narrows the list to forms matching the name filter" do
      filters = [{ name: { operator: "~", values: ["Hardware"] } }].to_json
      get forms_admin_settings_work_package_custom_field_path(custom_field, filters:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hardware form")
      expect(response.body).not_to include("Software form")
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
