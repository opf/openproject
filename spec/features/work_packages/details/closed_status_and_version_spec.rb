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

RSpec.describe "Closed status and version in full view", :js do
  let(:type) { create(:type) }
  let(:status) { create(:closed_status) }

  let(:project) { create(:project, types: [type]) }

  let(:version) { create(:version, status: "closed", project:) }
  let(:work_package) { create(:work_package, project:, status:, version:) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  let(:user) { create(:admin) }

  before do
    login_as(user)
    wp_page.visit!
  end

  it "shows a warning when trying to edit status" do
    # Should be initially editable (due to non specific schema)
    status = page.find("#{test_selector('op-wp-status-button')} button:not([disabled])")
    status.click

    wp_page.expect_and_dismiss_toaster type: :error,
                                       message: I18n.t("js.work_packages.message_work_package_status_blocked")

    expect(page).to have_css("#{test_selector('op-wp-status-button')} button[disabled]")
  end
end
