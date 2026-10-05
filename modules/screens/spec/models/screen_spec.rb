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

RSpec.describe Screen, type: :model do
  it "is valid with valid attributes" do
    expect(build(:screen)).to be_valid
  end

  it "requires a unique name" do
    create(:screen, name: "Shared")
    expect(build(:screen, name: "Shared")).not_to be_valid
  end

  it "rejects names longer than 255 characters" do
    expect(build(:screen, name: "a" * 256)).not_to be_valid
  end

  it "rejects descriptions longer than 5000 characters" do
    expect(build(:screen, description: "a" * 5001)).not_to be_valid
  end

  it "rejects an unknown screen_type" do
    screen = build(:screen)
    screen.screen_type = "foo"
    expect(screen).not_to be_valid
    expect(screen.errors.details[:screen_type]).to include(error: :inclusion)
  end

  it "does not change screen_type after creation" do
    screen = create(:screen, screen_type: "create")
    screen.update(screen_type: "edit")
    expect(screen.reload.screen_type).to eq("create")
  end

  it "cannot be destroyed" do
    screen = create(:screen)
    expect(screen.destroy).to be(false)
    expect(screen.errors.details[:base]).to include(error: :cannot_be_deleted)
    expect(Screen.exists?(screen.id)).to be(true)
  end

  it "resets the resolver cache when a section is destroyed" do
    section = create(:screen_section)
    expect(::Screens::Resolver).to receive(:reset_cache).once
    section.destroy
  end
end
