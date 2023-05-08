#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# require 'spec_helper'

# describe 'TimeEntry activities' do

#   # TO DO

#   # User logs time for a WP
#   # Activity is displayed as specified
#   # User updates log time duration and category
#   # Activity is updated as specified

# end

require 'spec_helper'

describe 'TimeEntry activities' do
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[log_time
                                      view_time_entries
                                      view_own_time_entries
                                      edit_own_time_entries
                                      view_work_packages
                                      edit_work_packages
                                      edit_time_entries])
  end
  let(:project) { create(:project_with_types, enabled_module_names: %w[costs activity work_package_tracking]) }
  let(:work_package) { create(:work_package, project:, type: project.types.first) }
  let(:hours) { 5.0 }
  let(:time_entry) do
    create(:time_entry,
           project:,
           work_package:,
           spent_on: Date.today,
           hours:,
           user:,
           comments: 'lorem ipsum')
  end

  before do
    login_as user
  end

  it 'tracks the time_entry\'s activities', js: true do
    work_package.save!
    time_entry.save!
    visit project_activity_index_path(project)

    check 'Spent time'
    uncheck 'Work packages'

    click_button 'Apply'

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_link("#{project.types.first} ##{work_package.id}: #{work_package.subject}")
      expect(page).to have_selector('li', text: "Spent time: #{time_entry.hours.to_i} hours")
      expect(page).to have_link('Details')
      click_link('Details')
    end

    expect(find_field('work_package_id_arg_1_val').value).to eq("#{work_package.id}")


  end
end
