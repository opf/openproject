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
#
require "spec_helper"

RSpec.describe My::TimeZoneForm, type: :forms do
  include_context "with rendered form"

  let(:model) { build_stubbed(:user_preference) }

  it "renders select list" do
    expect(page).to have_select "Time zone", required: true do |select|
      expect(select).to have_element :option, value: "America/Los_Angeles", text: "(UTC-08:00) Pacific Time (US & Canada)"
      expect(select).to have_element :option, value: "Europe/Berlin", text: "(UTC+01:00) Berlin, Copenhagen, Stockholm"
      expect(select).to have_element :option, value: "Asia/Shanghai", text: "(UTC+08:00) Beijing, Chongqing"
    end
  end
end
