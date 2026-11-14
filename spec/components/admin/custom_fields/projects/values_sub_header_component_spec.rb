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

RSpec.describe Admin::CustomFields::Projects::ValuesSubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project) }

  subject(:rendered) { render_inline(described_class.new(custom_field:, project:)) }

  context "when projects may add values" do
    let(:custom_field) { build_stubbed(:list_wp_custom_field, allow_additional_project_values: true) }

    it "opens a dialog to add a value" do
      expect(rendered).to have_link(
        I18n.t("custom_fields.admin.projects.new_value"),
        href: new_admin_settings_work_package_custom_field_project_specific_value_path(custom_field, project)
      )
      expect(rendered.css("a[data-controller='async-dialog']")).to be_present
    end
  end

  context "when projects may not add values" do
    let(:custom_field) { build_stubbed(:list_wp_custom_field, :project_specific_allowlist) }

    it "renders nothing" do
      expect(rendered.to_html).to be_empty
    end
  end
end
