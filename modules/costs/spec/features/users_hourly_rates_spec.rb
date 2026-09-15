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

require_relative "../spec_helper"

RSpec.describe "hourly rates on user edit", :js do
  let(:user) { create(:admin) }

  def view_rates
    visit edit_user_path(user, tab: "rates")
  end

  def expand_default_rates
    find("[data-test-selector='rate-history-default'] [data-collapsible-toggle]").click
  end

  before do
    login_as user
  end

  context "with no rates" do
    before do
      view_rates
    end

    it "shows no data message once the section is expanded" do
      expect(page).to have_no_text I18n.t("no_results_title_text")

      expand_default_rates

      expect(page).to have_text I18n.t("no_results_title_text")
    end
  end

  context "with rates" do
    let!(:rate) { create(:default_hourly_rate, user:, rate: 42) }

    before do
      view_rates
    end

    it "names the current rate in the collapsed section header" do
      expect(page).to have_text "42.00"
    end

    it "lists the rate history once the section is expanded" do
      expand_default_rates

      within "[data-test-selector='rate-history-default']" do
        expect(page).to have_text Rate.human_attribute_name(:valid_from)
        expect(page).to have_text "42.00"
      end
    end
  end
end
