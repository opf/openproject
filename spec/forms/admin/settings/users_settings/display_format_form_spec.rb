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

RSpec.describe Admin::Settings::UsersSettings::DisplayFormatForm, type: :forms do
  current_user { build_stubbed(:user, firstname: "Olga", lastname: "Operator", login: "olga") }

  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", scope: :settings } }

  it "renders" do
    expect(page).to have_select "Users name format", fieldset: "Display format" do |field|
      expect(field["name"]).to eq "settings[user_format]"
    end
  end

  it "renders the name of the current user in every format as options" do
    expect(page).to have_select "Users name format" do |select|
      options = select.all(:option).to_h { [it.text, it.value] }

      expect(options).to eq(
        "Olga Operator" => "firstname_lastname",
        "Olga" => "firstname",
        "Operator Olga" => "lastname_firstname",
        "OperatorOlga" => "lastname_n_firstname",
        "Operator, Olga" => "lastname_comma_firstname",
        "olga" => "username"
      )
    end
  end

  it "selects the default format" do
    expect(page).to have_select "Users name format", selected: "Olga Operator"
  end

  context "with another format set", with_settings: { user_format: :lastname_comma_firstname } do
    it "selects the set format" do
      expect(page).to have_select "Users name format", selected: "Operator, Olga"
    end
  end
end
