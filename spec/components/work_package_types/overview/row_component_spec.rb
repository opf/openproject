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

RSpec.describe WorkPackageTypes::Overview::RowComponent,
               type: :component,
               with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:source_type) { create(:type, name: "Feature") }
  shared_let(:variant) { type.default_variant }
  shared_let(:source) { source_type.default_variant }

  let(:aspect) { TypeVariant::WORKFLOWS }
  let(:tab) { { name: "workflow", path: "/workflow", label: "Workflows", aspect: } }
  let(:table) { WorkPackageTypes::Overview::TableComponent.new(variant:, tabs: [tab]) }

  subject(:row) { described_class.new(row: tab, table:) }

  describe "the setting" do
    it "links to its own tab" do
      render_inline(row)

      expect(page).to have_link("Workflows", href: "/workflow")
    end
  end

  describe "the configuration mode" do
    context "when the setting cannot be reused" do
      let(:aspect) { nil }

      it "reads always manual" do
        render_inline(row)

        expect(page).to have_text("Always manual")
      end
    end

    context "when a reusable setting is not inherited" do
      it "reads manually configured" do
        render_inline(row)

        expect(page).to have_text("Manually configured")
      end
    end

    context "when the setting is inherited" do
      before { link_configuration(variant, source:, aspect:) }

      it "names the source, linking to that setting on it" do
        render_inline(row)

        expect(page).to have_text("Inheriting from")
        expect(page).to have_link("Feature",
                                  href: edit_type_workflow_path(type_id: source.type_id, variant_id: source.id))
      end
    end
  end

  describe "the dependents" do
    it "are a dash when nothing depends on the setting" do
      render_inline(row)

      expect(page).to have_text("-")
      expect(page).to have_no_text("dependent type")
    end

    context "when the setting cannot be reused" do
      let(:aspect) { nil }

      it "are a dash" do
        render_inline(row)

        expect(page).to have_text("-")
      end
    end

    context "when another variant borrows the setting" do
      before { link_configuration(source, source: variant, aspect:) }

      it "are counted, opening their dialog" do
        render_inline(row)

        expect(page).to have_link(
          "1 dependent type",
          href: type_configuration_dependents_dialog_path(**variant.path_args, aspect:)
        )
      end
    end
  end
end
