# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "format_field_expectations"
require_relative "../shared_list_custom_field_journey"

RSpec.describe "users list custom fields", :js do
  let(:user) { create(:admin) }
  let(:section) { create(:user_custom_field_section, name: "Test section") }
  let(:cf_page) { Pages::Admin::Settings::UserCustomFields::Index.new }

  current_user { user }

  before { section }

  it_behaves_like "list custom field journey" do
    def open_new_list_field_form
      cf_page.visit!
      cf_page.click_to_create_new_custom_field "List"
    end
  end

  it_behaves_like "expected fields for the User custom field's format", "List"
end
