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

RSpec.describe "TimeEntry activity",
               :js,
               :with_cuprite,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[log_time
                                                    view_time_entries
                                                    view_own_time_entries
                                                    edit_own_time_entries
                                                    view_work_packages
                                                    edit_work_packages
                                                    edit_time_entries] })
  end
  let(:user2) { create(:user, firstname: "Peter", lastname: "Parker") }
  let(:project) { build(:project_with_types, enabled_module_names: %w[costs activity work_package_tracking]) }
  let(:time_entry_activity) { create(:time_entry_activity) }
  let(:time_entry_activity2) { create(:time_entry_activity) }
  let(:work_package) { create(:work_package, project:, type: project.types.first) }
  let(:work_package2) { build(:work_package, project:, type: project.types.second) }
  let!(:time_entry) do
    create(:time_entry,
           project:,
           work_package:,
           spent_on: Time.zone.today,
           hours: 5,
           user:,
           activity_id: time_entry_activity.id,
           comments: "lorem ipsum")
  end

  before do
    login_as user
  end

  it "tracks the time_entry's activities" do
    visit project_activity_index_path(project)

    check "Spent time"

    click_button "Apply"

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_link("#{project.types.first} ##{work_package.id}: #{work_package.subject}")
      expect(page).to have_css("li", text: "Spent time: 5 hours")
      expect(page).to have_link("Details")
      click_link("Details")
    end

    wait_for_reload

    expect(find_field("work_package_id_arg_1_val").value).to eq(work_package.id.to_s)

    old_comments = time_entry.comments
    old_spent_on = time_entry.spent_on

    new_attributes = {
      work_package: work_package2,
      spent_on: Time.zone.yesterday,
      hours: 1.0,
      user: user2,
      activity_id: time_entry_activity2.id,
      comments: "updated comment"
    }

    time_entry.update!(new_attributes)

    visit project_activity_index_path(project)

    check "Spent time"

    click_button "Apply"

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_link("#{project.types.first} ##{work_package2.id}: #{work_package2.subject}")
      expect(page).to have_css("li", text: "Logged for #{user2.name}")
      expect(page).to have_css("li", text: "Work package changed from #{work_package.name} to #{work_package2.name}")
      expect(page).to have_css("li", text: "Spent time changed from 5 hours to 1 hour")
      expect(page).to have_css("li", text: "Comment changed from #{old_comments} to #{time_entry.comments}")
      expect(page).to have_css("li",
                               text: "Activity changed from #{time_entry_activity.name} to #{time_entry_activity2.name}")
      expect(page).to have_css("li", text: "Date changed from #{old_spent_on} to #{time_entry.spent_on}")
      click_link("Details")
    end

    wait_for_reload

    expect(find_field("work_package_id_arg_1_val").value).to eq(work_package2.id.to_s)
  end
end
