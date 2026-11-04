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

RSpec.describe "Embedded GoodJob dashboard", :js, :selenium do
  let(:admin) { create(:admin) }

  it "loads GoodJob scripts, charts and navigation inside the administration page" do
    login_as admin
    visit admin_good_job_dashboard_path

    expect(page).to have_current_path(admin_good_job_dashboard_path)
    within_frame(find("iframe[title='GoodJob dashboard']")) do
      expect(page).to have_css("canvas", wait: 20)
      expect(page).to have_no_css("html[data-turbo-unloaded]", visible: :all)
      expect(page.evaluate_script("Object.keys(Chart.instances).length")).to be_positive

      find("a[href*='/processes']").click
      expect(page).to have_css("a[href*='/processes'].active", wait: 20)
    end

    expect(page).to have_current_path(admin_good_job_dashboard_path)
    expect(page).to have_css("iframe[title='GoodJob dashboard']")
  end
end
