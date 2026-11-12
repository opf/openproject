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

RSpec.describe Admin::CustomFields::Projects::DeleteValueDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project, name: "Scrum project") }
  let(:custom_field) { build_stubbed(:list_wp_custom_field) }
  let(:value) { build_stubbed(:custom_option, custom_field:, project:) }

  subject(:rendered) { render_inline(described_class.new(custom_field:, project:, value:)) }

  it "deletes the value of the project after confirmation" do
    form = rendered.css("form")

    expect(form.attr("action").value)
      .to eq(admin_settings_work_package_custom_field_project_specific_value_path(custom_field, project, value.id))
    expect(form.css("input[name='_method']").attr("value").value).to eq("delete")
    expect(rendered).to have_text(
      I18n.t("custom_fields.admin.projects.delete_value_dialog.description", project: "Scrum project")
    )
    expect(rendered).to have_field(type: "checkbox")
  end
end
