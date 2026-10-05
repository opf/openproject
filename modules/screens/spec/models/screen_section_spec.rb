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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScreenSection, type: :model do
  it "is valid" do
    expect(build(:screen_section)).to be_valid
  end

  it "rejects a duplicate name within a screen ignoring case" do
    screen = create(:screen)
    create(:screen_section, screen:, name: "General")
    expect(build(:screen_section, screen:, name: "general")).not_to be_valid
  end

  it "allows the same name on different screens" do
    create(:screen_section, name: "General")
    expect(build(:screen_section, name: "General")).to be_valid
  end

  it "rejects a position outside the allowed range" do
    expect(build(:screen_section, position: -1)).not_to be_valid
    expect(build(:screen_section, position: 100_000)).not_to be_valid
  end
end
