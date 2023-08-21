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

require 'spec_helper'

RSpec.describe 'index users', js: true, with_cuprite: true do
  current_user { create(:admin) }

  let(:index_page) { Pages::Admin::Users::Index.new }

  it 'displays the user activity list', with_settings: { journal_aggregation_time_minutes: 0 } do
    # create some activities
    project = create(:project_with_types)
    project.update(name: 'new name', description: 'new project description')

    work_package = create(:work_package, author: current_user, project:)
    work_package.update(subject: 'new subject', description: 'new work package description')

    visit user_path(current_user)

    expect(page).to have_selector('li', text: "Project: #{project.name}")
    expected_work_package_title = "#{work_package.type.name} ##{work_package.id}: #{work_package.subject} " \
                                  "(Project: #{work_package.project.name})"
    expect(page).to have_selector('li', text: expected_work_package_title)
  end
end
