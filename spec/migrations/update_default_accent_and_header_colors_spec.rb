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

require "spec_helper"
require Rails.root.join("db/migrate/20261029120000_update_default_accent_and_header_colors.rb")

RSpec.describe UpdateDefaultAccentAndHeaderColors, type: :model do
  let!(:custom_style) { create(:custom_style, updated_at: 1.day.ago) }

  def hexcode_of(variable) = DesignColor.find_by(variable:).hexcode

  describe "#up" do
    subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

    context "with the previous default colors" do
      before do
        create(:design_color, variable: "accent-color", hexcode: "#1A67A3")
        create(:design_color, variable: "header-bg-color", hexcode: "#1A67A3")
        create(:design_color, variable: "main-menu-bg-selected-background", hexcode: "#175A8E")
      end

      it "replaces them with the new defaults and invalidates the custom style cache" do
        expect { migrate }.to change { custom_style.reload.updated_at }

        expect(hexcode_of("accent-color")).to eq "#0F41B5"
        expect(hexcode_of("header-bg-color")).to eq "#0F41B5"
        expect(hexcode_of("main-menu-bg-selected-background")).to eq "#0F41B5"
      end
    end

    context "with custom colors" do
      before do
        create(:design_color, variable: "accent-color", hexcode: "#ABC123")
        create(:design_color, variable: "header-bg-color", hexcode: "#175A8E")
      end

      it "keeps them and leaves the custom style untouched" do
        expect { migrate }.not_to change { custom_style.reload.updated_at }

        expect(hexcode_of("accent-color")).to eq "#ABC123"
        expect(hexcode_of("header-bg-color")).to eq "#175A8E"
      end
    end
  end

  describe "#down" do
    subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.down } }

    before do
      create(:design_color, variable: "accent-color", hexcode: "#0F41B5")
      create(:design_color, variable: "header-bg-color", hexcode: "#0F41B5")
      create(:design_color, variable: "main-menu-bg-selected-background", hexcode: "#0F41B5")
    end

    it "restores the previous defaults and invalidates the custom style cache" do
      expect { migrate }.to change { custom_style.reload.updated_at }

      expect(hexcode_of("accent-color")).to eq "#1A67A3"
      expect(hexcode_of("header-bg-color")).to eq "#1A67A3"
      expect(hexcode_of("main-menu-bg-selected-background")).to eq "#175A8E"
    end
  end
end
