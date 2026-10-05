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

RSpec.describe ScreenSchemeItem, type: :model do
  it "is valid" do
    expect(build(:screen_scheme_item)).to be_valid
  end

  it "requires at least one screen" do
    item = build(:screen_scheme_item, create_screen: nil)
    expect(item).not_to be_valid
    expect(item.errors.details[:base]).to include(error: :at_least_one_screen)
  end

  it "rejects a screen whose type does not match the slot" do
    item = build(:screen_scheme_item, create_screen: build(:edit_screen))
    expect(item).not_to be_valid
    expect(item.errors.details[:create_screen]).to include(error: :context_mismatch)
  end

  it "rejects duplicate types within a scheme" do
    item = create(:screen_scheme_item)
    duplicate = build(:screen_scheme_item, scheme: item.scheme, type: item.type, create_screen: build(:create_screen))
    expect(duplicate).not_to be_valid
  end
end
