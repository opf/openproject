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

RSpec.describe Admin::Settings::ProjectReservedIdentifiers::ReleaseDialogComponent, type: :component do
  let!(:project) { create(:project) }
  let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

  subject(:rendered_component) { render_inline(described_class.new(slug:)) }

  it "renders the heading with the identifier" do
    expect(rendered_component)
      .to have_text(I18n.t("admin.reserved_identifiers.dialog.heading", identifier: "old-id"))
  end

  context "without affected work packages" do
    it "renders the plain description" do
      expect(rendered_component)
        .to have_text(I18n.t("admin.reserved_identifiers.dialog.description"))
      expect(rendered_component).to have_no_text("work package")
    end
  end

  context "with one affected work package" do
    before { create(:work_package_semantic_alias, identifier: "old-id-1") }

    it "renders the singular description" do
      expect(rendered_component)
        .to have_text(I18n.t("admin.reserved_identifiers.dialog.description_with_work_packages", count: 1))
    end
  end

  context "with several affected work packages" do
    before do
      create(:work_package_semantic_alias, identifier: "old-id-1")
      create(:work_package_semantic_alias, identifier: "old-id-2")
    end

    it "renders the pluralized description" do
      expect(rendered_component)
        .to have_text(I18n.t("admin.reserved_identifiers.dialog.description_with_work_packages", count: 2))
    end
  end
end
