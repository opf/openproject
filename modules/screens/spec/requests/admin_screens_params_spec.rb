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
require "rack/test"

RSpec.describe "Admin screens strong parameters" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods

  shared_let(:admin) { create(:admin) }
  shared_let(:screen) { create(:create_screen) }
  shared_let(:other_screen) { create(:create_screen, name: "Other") }
  shared_let(:other_section) { create(:screen_section, screen: other_screen, name: "Foreign") }

  before { login_as(admin) }

  it "ignores screen_type on update" do
    patch admin_screen_path(screen), screen: { name: "Renamed", screen_type: "edit" }
    expect(screen.reload.screen_type).to eq("create")
    expect(screen.name).to eq("Renamed")
  end

  it "ignores a foreign section id instead of moving the other screen's section" do
    patch admin_screen_path(screen), screen: {
      sections: { "0" => { "id" => other_section.id, "name" => "Injected",
                           "position" => "1", "items" => {} } }
    }

    expect(other_section.reload.screen_id).to eq(other_screen.id)
    expect(other_section.name).to eq("Foreign")
  end
end
