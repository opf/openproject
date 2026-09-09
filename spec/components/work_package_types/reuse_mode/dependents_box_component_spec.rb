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

RSpec.describe WorkPackageTypes::ReuseMode::DependentsBoxComponent, type: :component, with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:variant) { type.default_variant }
  shared_let(:borrowing_type) { create(:type, name: "Feature") }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  subject(:component) { described_class.new(variant:, aspect:) }

  context "when nothing borrows the aspect" do
    before { render_inline(component) }

    it "shows the blank state without a warning" do
      expect(page).to have_text("No dependent types")
      expect(page).to have_text("No other type or variant inherits from this configuration")
      expect(page).to have_no_css(".color-bg-attention")
    end

    it "offers no action" do
      expect(page).to have_no_link("View dependent types")
    end
  end

  context "when other variants borrow the aspect" do
    before do
      link_configuration(borrowing_type.default_variant, source: variant, aspect:)
      link_configuration(create(:type_variant, type: borrowing_type, variant_name: "Hardware"), source: variant, aspect:)

      render_inline(component)
    end

    it "counts the dependents in the title and the description" do
      expect(page).to have_text("2 dependent types")
      expect(page).to have_text("inherited by 2 other types or variants")
    end

    it "warns about them" do
      expect(page).to have_css(".color-bg-attention")
    end

    it "links the action to the dependents dialog" do
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{type_configuration_dependents_dialog_path(type_id: type.id, aspect:)}']",
        text: "View dependent types"
      )
    end
  end

  context "when a single variant borrows the aspect" do
    before do
      link_configuration(borrowing_type.default_variant, source: variant, aspect:)

      render_inline(component)
    end

    it "uses the singular" do
      expect(page).to have_text("1 dependent type")
      expect(page).to have_text("inherited by 1 other type or variant")
    end
  end

  context "when a variant borrows through another variant" do
    before do
      link_configuration(borrowing_type.default_variant, source: variant, aspect:)
      link_configuration(create(:type, name: "Bug").default_variant, source: borrowing_type.default_variant, aspect:)

      render_inline(component)
    end

    it "counts the whole chain as one total" do
      expect(page).to have_text("2 dependent types")
    end

    it "warns about them" do
      expect(page).to have_css(".color-bg-attention")
    end
  end

  context "when another aspect is borrowed instead" do
    before do
      link_configuration(borrowing_type.default_variant, source: variant, aspect: TypeVariant::WORKFLOWS)

      render_inline(component)
    end

    it "counts only the shown aspect" do
      expect(page).to have_text("No dependent types")
    end
  end
end
