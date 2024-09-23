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

require "spec_helper"

RSpec.describe "Notifications sent on shared work packages",
               :js,
               :with_cuprite,
               with_ee: %i[work_package_sharing] do
  # Notice that the setup in this file here is not following the normal rules as
  # it also tests notification creation.
  let!(:project) { create(:project) }
  let!(:work_package_editor_role) { create(:edit_work_package_role) }
  let!(:recipient) do
    # Needs to take place before the work package is created so that the notification listener is set up
    create(:user,
           notification_settings: [build(:notification_setting, all: true)])
  end
  let!(:other_user) do
    create(:user)
  end
  let(:work_package) do
    create(:work_package,
           :created_in_past,
           project:,
           author: other_user,
           created_at: 5.days.ago)
  end
  let(:work_package_share) do
    create(:work_package_member,
           principal: recipient,
           entity: work_package,
           project: work_package.project,
           roles: [work_package_editor_role])
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:side_menu) { Components::Submenu.new }

  describe "notification for being mentioned" do
    before do
      # The notifications need to be created as a different user
      # as they are otherwise swallowed to avoid self notification.
      User.execute_as(other_user) do
        perform_enqueued_jobs do
          work_package_share

          work_package.journal_notes = "Hey user##{recipient.id}, get this."
          work_package.save!
        end
      end
    end

    it "mentioned user receives a notification" do
      login_as(recipient)

      visit home_path
      wait_for_reload
      center.expect_bell_count 1
      center.open

      notification_mentioned = work_package.journals.reload.last.notifications.first

      center.expect_work_package_item notification_mentioned

      side_menu.click_item "Mentioned"
      side_menu.finished_loading
      center.expect_work_package_item notification_mentioned
    end
  end

  describe "notification for being shared with" do
    before do
      # The notifications need to be created as a different user
      # as they are otherwise swallowed to avoid self notification.
      User.execute_as(other_user) do
        perform_enqueued_jobs do
          work_package_share

          work_package.subject = "Changed this just now"
          work_package.save!
        end
      end
    end

    it "shared with user receives notification" do
      login_as(recipient)

      visit home_path
      wait_for_reload
      center.expect_bell_count 1
      center.open

      notification_shared = work_package.journals.reload.last.notifications.first

      center.expect_work_package_item notification_shared

      side_menu.click_item "Shared"
      side_menu.finished_loading
      center.expect_work_package_item notification_shared
    end
  end
end
