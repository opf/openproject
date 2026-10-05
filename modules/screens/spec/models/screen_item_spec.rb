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

RSpec.describe ScreenItem, type: :model do
  it "is valid" do
    expect(build(:screen_item)).to be_valid
  end

  it "rejects a field_key not matching the format" do
    expect(build(:screen_item, field_key: "Bad Key")).not_to be_valid
    expect(build(:screen_item, field_key: "1abc")).not_to be_valid
  end

  it "rejects a field_key longer than 64 characters" do
    expect(build(:screen_item, field_key: "a" * 65)).not_to be_valid
  end

  it "rejects a duplicate field_key within a screen" do
    screen = create(:screen)
    section = create(:screen_section, screen:)
    create(:screen_item, screen:, section:, field_key: "subject")
    duplicate = build(:screen_item, screen:, section:, field_key: "subject")
    expect(duplicate).not_to be_valid
  end

  it "rejects an unknown width" do
    expect(build(:screen_item, width: "third")).not_to be_valid
  end

  it "rejects a position outside the allowed range" do
    expect(build(:screen_item, position: -1)).not_to be_valid
    expect(build(:screen_item, position: 100_000)).not_to be_valid
  end
end
