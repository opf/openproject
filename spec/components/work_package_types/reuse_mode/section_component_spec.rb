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

RSpec.describe WorkPackageTypes::ReuseMode::SectionComponent, type: :component, with_flag: { type_variants: true } do
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:variant) { type.default_variant }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  subject(:component) { described_class.new(variant:, aspect:) }

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    it "does not render" do
      render_inline(component)

      expect(page.text).to be_blank
    end
  end

  context "with the feature enabled" do
    before { render_inline(component) }

    it "shows the reuse mode and the dependents side by side" do
      expect(page).to have_text("Manual configuration")
      expect(page).to have_text("No dependent types")
    end

    it "gives both boxes half of the row" do
      expect(page).to have_css(".d-flex.flex-column.flex-md-row.gap-3")
      expect(page).to have_css(".flex-1", count: 2)
    end
  end
end
