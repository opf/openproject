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

require "rails_helper"

RSpec.describe "Work Package Sharing Enterprise Restriction", :js, :with_cuprite do
  shared_let(:view_work_package_role)    { create(:view_work_package_role)    }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:edit_work_package_role)    { create(:edit_work_package_role)    }

  shared_let(:sharer_role) do
    create(:project_role, permissions: %i[view_work_packages
                                          view_shared_work_packages
                                          share_work_packages])
  end

  shared_let(:sharer) { create(:user, firstname: "Sharer", lastname: "User") }

  shared_let(:project)      { create(:project, members: { sharer => [sharer_role] }) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal)       { Components::Sharing::WorkPackages::ShareModal.new(work_package) }

  current_user { sharer }

  before do
    work_package_page.visit!
    work_package_page.click_share_button

    share_modal.expect_open
  end

  context "without an enterprise token" do
    it "renders an upsale banner" do
      share_modal.expect_upsale_banner
    end
  end

  context "with an enterprise token", with_ee: %i[work_package_sharing] do
    it "renders the share modal" do
      share_modal.expect_blankslate
    end
  end
end
