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

require "rails_helper"
require_relative "shared_examples"

RSpec.describe "user notifications settings",
               :js do
  shared_let(:user) { create(:user) }

  let(:settings_page) { Pages::Notifications::Settings.new(user) }

  before do
    login_as current_user
    settings_page.visit!
  end

  context "as an admin" do
    let(:current_user) { create(:admin) }

    it_behaves_like "notification settings workflow"
  end

  context "as a regular user" do
    let(:current_user) { create(:user) }

    it "does not allow to visit the page" do
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end
