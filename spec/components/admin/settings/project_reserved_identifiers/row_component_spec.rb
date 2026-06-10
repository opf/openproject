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

RSpec.describe Admin::Settings::ProjectReservedIdentifiers::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let!(:project) { create(:project, identifier: "current-id", name: "My Project") }
  let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

  subject(:rendered_component) do
    render_inline(
      Admin::Settings::ProjectReservedIdentifiers::TableComponent.new(rows: [slug])
    )
  end

  it "renders a link to the project overview" do
    expect(rendered_component).to have_link("My Project",
                                            href: project_overview_path(project))
  end

  it "renders the identifier slug" do
    expect(rendered_component).to have_text("old-id")
  end

  it "renders a Release danger button pointing to the confirm dialog" do
    expect(rendered_component).to have_link(
      I18n.t("admin.reserved_identifiers.btn_release"),
      href: confirm_dialog_admin_settings_project_reserved_identifier_path(slug.id)
    )
  end
end
