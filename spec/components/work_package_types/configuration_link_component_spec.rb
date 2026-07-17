# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe WorkPackageTypes::ConfigurationLinkComponent, type: :component do
  let(:source) { create(:type, name: "Phase") }
  let(:type) { create(:type) }

  before do
    allow(OpenProject::FeatureDecisions).to receive(:subtypes_active?).and_return(true)
    login_as(create(:admin))
  end

  context "when the aspect is linked" do
    before { type.link!(Type::ConfigurationLink::PATTERNS, source:) }

    it "renders the source reference and the readonly preview slot", :aggregate_failures do
      render_inline(described_class.new(type:, aspect: Type::ConfigurationLink::PATTERNS)) do |c|
        c.with_readonly_preview { "PREVIEW_MARKER" }
      end

      expect(page).to have_text("Configuration reused from Phase")
      expect(page).to have_text("PREVIEW_MARKER")
    end
  end

  context "when the aspect is independent" do
    it "does not render the readonly preview" do
      render_inline(described_class.new(type:, aspect: Type::ConfigurationLink::PATTERNS)) do |c|
        c.with_readonly_preview { "PREVIEW_MARKER" }
      end

      expect(page).to have_no_text("PREVIEW_MARKER")
    end
  end
end
