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
require "features/page_objects/notification"

RSpec.describe "Notification center date alert and mention",
               :js,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user, firstname: "Actor", lastname: "User") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages] })
  end
  let(:reference_time) { Time.zone.local(2025, 1, 8, 12, 0, 0) }
  let(:work_package) { create(:work_package, project:, due_date: 1.day.ago.to_date) }
  let!(:notification_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: work_package,
           actor:)
  end

  let!(:notification_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: work_package)
  end

  let(:center) { Pages::Notifications::Center.new }

  before do
    travel_to(reference_time)
    login_as user
    visit notifications_center_path
    wait_for_reload
  end

  after do
    travel_back
  end

  it "shows only the date alert time, not the mentioned author" do
    center.within_item(notification_date_alert) do
      expect(page).to have_text("##{work_package.id}\n- #{project.name} -\nDate alert, Mentioned")
      expect(page).to have_no_text("Actor User")
      expect(page).to have_text("Overdue for 1 day.")
    end
  end
end
