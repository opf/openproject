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

RSpec.describe Settings::TimeZoneSettingComponent, type: :component do
  subject { render_inline(described_class.new("user_default_timezone")) }

  it "renders the timezones as options, grouping cities with the same identifier" do
    subject

    expect(page).to have_css("option[value=\"America/Los_Angeles\"]",
                             text: "(UTC-08:00) Pacific Time (US & Canada)")
    expect(page).to have_css("option[value=\"Europe/Berlin\"]", text: "(UTC+01:00) Berlin, Copenhagen, Stockholm")
    expect(page).to have_css("option[value=\"Asia/Shanghai\"]", text: "(UTC+08:00) Beijing, Chongqing")
  end
end
