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

RSpec.describe WorkPackageTypes::ReuseMode::SectionComponent, type: :component do
  shared_let(:type) { create(:type, name: "Task") }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  subject(:component) { described_class.new(variant:, aspect:) }

  context "for a named variant" do
    let(:variant) { create(:type_variant, type:) }

    before { render_inline(component) }

    it "renders the mode selector" do
      expect(page).to have_text("Use the same settings as the type")
      expect(page).to have_text("Configure this page manually")
    end
  end

  context "for the base variant" do
    let(:variant) { type.default_variant }

    it "renders nothing, since a base variant has no mode to choose" do
      render_inline(component)

      expect(page).to have_no_text("Use the same settings as the type")
      expect(page).to have_no_text("Configure this page manually")
    end
  end
end
