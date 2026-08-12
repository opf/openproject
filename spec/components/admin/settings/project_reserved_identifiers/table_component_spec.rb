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

RSpec.describe Admin::Settings::ProjectReservedIdentifiers::TableComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(rows:)) }

  shared_examples_for "rendering column headings" do
    it_behaves_like "rendering Border Box Grid heading", text: "Project"
    it_behaves_like "rendering Border Box Grid heading", text: "Identifier"
    it_behaves_like "rendering Border Box Grid mobile heading", text: "Reserved project identifiers"
  end

  context "with no slugs" do
    let(:rows) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering column headings"
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t("admin.reserved_identifiers.empty_heading"),
                    icon: :"check-circle"
  end

  context "with slugs" do
    let!(:project) { create(:project, identifier: "current-id") }
    let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }
    let(:rows) { [slug] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering column headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 1, col_count: 2

    it "renders the identifier" do
      expect(rendered_component).to have_text("old-id")
    end

    it "renders a Release button" do
      expect(rendered_component).to have_text(I18n.t("admin.reserved_identifiers.btn_release"))
    end
  end
end
