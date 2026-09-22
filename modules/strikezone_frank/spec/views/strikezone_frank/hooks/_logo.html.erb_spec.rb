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

require "spec_helper"

RSpec.describe "strikezone_frank/hooks/logo" do
  it "overrides the OpenProject header logo with Strikezone assets" do
    render partial: "strikezone_frank/hooks/logo"

    expect(rendered).to include("strikezone_frank/logo-white")
    expect(rendered).to include("strikezone_frank/logo-black")
    expect(rendered).to include("strikezone_frank/icon")
    expect(rendered).to include(".op-logo--link")
    expect(rendered).to include(".op-logo--icon")
  end

  it "injects Strikezone theme colour tokens including derived hover colours" do
    render partial: "strikezone_frank/hooks/logo"

    expect(rendered).to include("--primary-button-color: #DF5301")
    expect(rendered).to include("--accent-color: #ED6718")
    expect(rendered).to include("--header-bg-color: #101010")
    expect(rendered).to include("--primary-button-color--major1:")
    expect(rendered).to include("--accent-color--major1:")
    expect(rendered).not_to include("--primary-button-color--major1: #197032")
  end

  it "loads Baloo Bhaina 2 and applies it as the UI font family" do
    render partial: "strikezone_frank/hooks/logo"

    expect(rendered).to include("@font-face")
    expect(rendered).to include("Baloo Bhaina 2")
    expect(rendered).to include("baloo-bhaina-2-latin-400")
    expect(rendered).to include("baloo-bhaina-2-latin-700")
    expect(rendered).to include("--body-font-family:")
    expect(rendered).to include("--text-title-size-large: 2.5rem")
    expect(rendered).to include(".Button--large")
  end
end
