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
require Rails.root.join("modules/screens/db/migrate/20261005210000_create_screens").to_s

RSpec.describe CreateScreens do
  it "can roll back and migrate again while the tables hold data" do
    screen = create(:create_screen)
    section = create(:screen_section, screen:)
    create(:screen_item, screen:, section:, field_key: "subject")

    migration = described_class.new
    migration.migrate(:down)
    migration.migrate(:up)
    [Screen, ScreenSection, ScreenItem].each(&:reset_column_information)

    expect(Screen.count).to eq(0)
    expect { create(:create_screen) }.not_to raise_error
  end
end
