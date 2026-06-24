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

RSpec.describe Users::Form::AttributesForm, type: :forms do
  before do
    User.current = current_user
  end

  include_context "with rendered form"

  let(:current_user) { build_stubbed(:admin) }
  let(:contract) { instance_double(Users::UpdateContract, writable?: true) }
  let(:params) { { user: model, contract: } }

  context "for a persisted user" do
    let(:model) { build_stubbed(:user) }

    it "renders the built-in fields, login and the admin flag" do
      expect(page).to have_field("user[firstname]")
      expect(page).to have_field("user[lastname]")
      expect(page).to have_field("user[mail]")
      expect(page).to have_select("user[language]")
      expect(page).to have_field("user[login]")
      expect(page).to have_field("user[admin]")
    end
  end

  context "for a new user" do
    let(:model) { User.new }

    it "omits the login field" do
      expect(page).to have_no_field("user[login]")
    end
  end

  context "with a section that has no visible content" do
    let(:model) { build_stubbed(:user) }

    before do
      create(:user_custom_field_section, name: "Empty", attribute_order: [])
    end

    it "does not render an empty section fieldset" do
      expect(page).to have_no_css("fieldset", text: "Empty")
    end
  end
end
