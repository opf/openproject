# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe 'Shared User Access',
               :js, :with_cuprite,
               with_ee: %i[work_package_sharing],
               with_flag: { work_package_sharing: true } do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:sharer) do
    create(:user,
           member_with_permissions: { project => %i[share_work_packages
                                                    view_shared_work_packages
                                                    view_work_packages] })
  end
  shared_let(:shared_with_user) { create(:user, firstname: 'Mean', lastname: 'Turkey') }

  shared_let(:viewer_role) { create(:view_work_package_role) }
  shared_let(:commenter_role) { create(:comment_work_package_role) }
  shared_let(:editor_role) { create(:edit_work_package_role) }

  let(:projects_page) { Pages::Projects::Index.new }
  let(:project_page) { Pages::Projects::Show.new(project) }
  let(:projects_top_menu) { Components::Projects::TopMenu.new }
  let(:global_work_packages_page) { Pages::WorkPackagesTable.new }
  let(:work_packages_page) { Pages::WorkPackagesTable.new(project) }
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::WorkPackages::ShareModal.new(work_package) }

  specify "Work Package Access" do
    using_session "shared-with user" do
      login_as(shared_with_user)

      #
      # Work Package's project is not visible without the work package having been shared
      # 1. Via the Project's Index Page
      projects_page.visit!
      projects_page.expect_projects_not_listed(project)

      # 2. Via the Projects dropdown in the top menu
      projects_top_menu.toggle!
      projects_top_menu.expect_blankslate

      # 3. Visiting the Project's URL directly
      project_page.visit!
      project_page.expect_toast(type: :error, message: I18n.t(:notice_not_authorized))

      #
      # Work Package is not visible without the work package having been shared
      # 1. Via the Work Packages Global Index Page
      global_work_packages_page.visit!
      global_work_packages_page.expect_toast(type: :error, message: I18n.t(:notice_not_authorized))

      # 2. Via the URL to work package
      work_package_page.visit!
      work_package_page.expect_toast(type: :error, message: I18n.t(:notice_file_not_found))
    end

    using_session "sharer" do
      # Sharing the Work Package with "View" access
      login_as(sharer)

      work_package_page.visit!
      work_package_page.click_share_button
      share_modal.expect_open

      share_modal.invite_user(shared_with_user, 'View')
      share_modal.expect_shared_with(shared_with_user)
    end

    using_session "shared-with user" do
      # Work Package's project is now listed
      # 1. Via the Projects Index Page
      projects_page.visit!
      projects_page.expect_projects_listed(project)

      # 2. Via the Projects dropdown in the top menu
      projects_top_menu.toggle!
      projects_top_menu.expect_result(project.name)

      # 3. Visiting the Project's URL directly
      project_page.visit!

      #
      # Work Package is now visible
      project_page.within_sidebar do
        click_link(I18n.t('label_work_package_plural'))
      end
      work_packages_page.expect_work_package_listed(work_package)
      work_package_page.visit!

      expect(page)
        .to have_text(work_package.subject)
    end
  end
end
