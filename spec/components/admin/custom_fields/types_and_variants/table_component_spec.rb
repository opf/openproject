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

require "rails_helper"

RSpec.describe Admin::CustomFields::TypesAndVariants::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:form) { create(:form_configuration, name: "Hardware form") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware", form_configuration: form) }

  def render_rows(rows)
    with_request_url "/admin/settings/work_package_custom_fields/1/types_and_variants" do
      render_inline(described_class.new(rows:))
    end
  end

  it "links the base variant to its type's form configuration and shows the form" do
    base = type.default_variant

    rendered = render_rows([base])

    expect(rendered).to have_link(type.name, href: edit_type_form_configuration_path(type))
    expect(rendered).to have_link(base.form_configuration.name, href: edit_form_configuration_path(base.form_configuration))
  end

  it "links a named variant to its own form configuration edit page" do
    rendered = render_rows([variant])

    expect(rendered).to have_link("Bug: Hardware", href: edit_type_variant_form_configuration_path(type, variant))
    expect(rendered).to have_link("Hardware form", href: edit_form_configuration_path(form))
  end

  it "links a project-owned variant to its project-scoped form configuration edit page" do
    project = create(:project)
    owned = create(:project_owned_type_variant, type:, variant_name: "Owned", project:, form_configuration: form)

    rendered = render_rows([owned])

    expect(rendered).to have_link("Bug: Owned",
                                  href: edit_project_type_variant_form_configuration_path(project, type, owned))
  end
end
