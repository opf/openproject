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

RSpec.describe Settings::AuthenticationSettingsForm, type: :forms do
  include ViewComponent::TestHelpers

  def render_form
    render_in_view_context(described_class) do |described_class|
      primer_form_with(url: "/foo") do |f|
        render(described_class.new(f))
      end
    end
  end

  before do
    render_form
  end

  it "renders 'Autologin' select list" do
    expect(page).to have_select "Autologin"
  end

  it "renders 'Session expires' checkbox" do
    expect(page).to have_unchecked_field "Session expires"
  end

  it "renders 'Session expiration time after inactivity' number field" do
    expect(page).to have_field "Session expiration time after inactivity", type: "number"
  end

  it "renders 'Log user login, name, and mail address for all requests' checkbox" do
    expect(page).to have_unchecked_field "Log user login, name, and mail address for all requests"
  end

  it "renders 'First login redirect' text field" do
    expect(page).to have_field "First login redirect"
  end

  it "renders 'After login redirect' text field" do
    expect(page).to have_field "After login redirect"
  end

  it "renders Save button" do
    expect(page).to have_button "Save", class: "Button--primary"
  end
end
