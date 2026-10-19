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

RSpec.describe "Zen mode", :js do
  let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           edit_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end

  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let(:work_package) do
    create(:work_package, project:, type:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:status_from) { work_package.status }
  let(:status_intermediate) { create(:status) }

  before do
    login_as(dev)

    work_package

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "hides menus" do
    wp_page.expect_no_zen_mode
    wp_page.page.find_by_id("work-packages-zen-mode-toggle-button").click
    wp_page.expect_zen_mode
    wp_page.page.find_by_id("work-packages-zen-mode-toggle-button").click
    wp_page.expect_no_zen_mode
  end
end
