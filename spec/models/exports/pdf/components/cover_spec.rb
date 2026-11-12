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

RSpec.describe Exports::PDF::Components::Cover do
  let(:cover) { Class.new { extend Exports::PDF::Components::Cover } }

  describe "#cover_text_color and #validate_cover_text_color" do
    it "returns nil when no CustomStyle is present" do
      allow(CustomStyle).to receive(:current).and_return(nil)
      expect(cover.cover_text_color).to be_nil
    end

    it "returns nil when the cover text color is blank" do
      allow(CustomStyle).to receive(:current).and_return(instance_double(CustomStyle, export_cover_text_color: ""))
      expect(cover.cover_text_color).to be_nil
    end

    it "returns nil when the cover text color is invalid" do
      allow(CustomStyle).to receive(:current).and_return(instance_double(CustomStyle, export_cover_text_color: "#abcdefg"))
      expect(cover.cover_text_color).to be_nil
    end

    it "returns a hex color without leading # when valid" do
      cs = instance_double(CustomStyle, export_cover_text_color: "#112233")
      allow(CustomStyle).to receive(:current).and_return(cs)
      expect(cover.cover_text_color).to eq "112233"
    end

    it "returns a normalized hex color without leading # when valid" do
      cs = instance_double(CustomStyle, export_cover_text_color: "#000")
      allow(CustomStyle).to receive(:current).and_return(cs)
      expect(cover.cover_text_color).to eq "000000"
    end
  end
end
