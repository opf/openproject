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

RSpec.describe "Time entry activities admin", :js do
  include Flash::Expectations
  include EnumerationAdminHelpers

  current_user { create(:admin) }

  let!(:alpha) { create(:time_entry_activity, name: "Alpha") }
  let!(:beta) { create(:time_entry_activity, name: "Beta") }
  let!(:gamma) { create(:time_entry_activity, name: "Gamma") }

  before do
    gamma.move_to_top
    beta.move_to_top
    alpha.move_to_top
  end

  def enumeration_list_selector = "#admin-enumerations-index-component"
  def enumeration_actions_label = "Actions"

  it "reorders through the move menu" do
    visit admin_settings_time_entry_activities_path

    expect_enumeration_order("Alpha", "Beta", "Gamma")

    move_enumeration(gamma, I18n.t(:label_sort_highest))

    expect_enumeration_move_settled("Gamma", "Alpha", "Beta")

    refresh

    expect_enumeration_order("Gamma", "Alpha", "Beta")
  end
end
