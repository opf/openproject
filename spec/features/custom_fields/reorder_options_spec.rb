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

def get_possible_values(amount)
  (1..amount).to_a.map { |x| "PREFIX #{x}" }
end

def get_shuffled_possible_values(amount)
  get_possible_values(amount).shuffle(random: Random.new(2))
end

def get_possible_values_reordered(amount)
  get_possible_values(amount).sort
end

RSpec.describe "Reordering custom options of a list custom field", :js, :selenium do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }

  let!(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Platform",
      possible_values: get_shuffled_possible_values(200)
    )
  end

  before do
    login_as(user)
  end

  it "reorders the items alphabetically when pressed" do
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq get_shuffled_possible_values(200)

    cf_page.visit!
    click_link custom_field.name

    wait_for_network_idle
    click_link "Items"
    wait_for_network_idle

    click_link "Reorder values alphabetically"
    cf_page.accept_alert_dialog!
    expect_flash(message: I18n.t(:notice_successful_update))
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq get_possible_values_reordered(200)
  end
end
