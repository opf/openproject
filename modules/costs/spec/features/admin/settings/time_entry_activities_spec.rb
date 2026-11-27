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

require "spec_helper"
require_relative "../../../support/pages/admin/time_entry_activities"

RSpec.describe "Time entry activities admin", :js do
  include Flash::Expectations

  current_user { create(:admin) }

  let!(:alpha) { create(:time_entry_activity, name: "Alpha") }
  let!(:beta) { create(:time_entry_activity, name: "Beta") }
  let!(:gamma) { create(:time_entry_activity, name: "Gamma") }
  let(:list_page) { Pages::Admin::TimeEntryActivities.new }

  before do
    gamma.move_to_top
    beta.move_to_top
    alpha.move_to_top
  end

  it "reorders through the move menu" do
    list_page.visit!

    list_page.expect_order("Alpha", "Beta", "Gamma")

    list_page.move(gamma, I18n.t(:label_sort_highest))

    list_page.expect_move_settled("Gamma", "Alpha", "Beta")

    refresh

    list_page.expect_order("Gamma", "Alpha", "Beta")
  end
end
