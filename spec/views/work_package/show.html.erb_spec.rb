#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'work_packages/show' do
  let(:story_points) { 42 }
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:public_project) }
  let(:story_type) { FactoryGirl.create(:type_feature) }
  let(:status) { FactoryGirl.create(:default_status) }
  let(:story) { FactoryGirl.create(:story,
                                   author: user,
                                   type: story_type,
                                   project: project,
                                   status: status,
                                   story_points: story_points) }

  before do
    view.stub(:current_menu_item).and_return(:work_packages)
    view.stub(:current_user).and_return(user)

    controller.stub(:work_package).and_return(story)
    controller.stub(:ancestors).and_return([])

    story.stub(:backlogs_enabled?).and_return(true)
    story.stub(:is_story?).and_return(true)

    assign(:project, project)

    render template: 'work_packages/show', locals: { work_package: story,
                                                     project: story.project,
                                                     priorities: [],
                                                     user: user,
                                                     ancestors: [],
                                                     descendants: [],
                                                     changesets: [],
                                                     relations: [],
                                                     journals: [] }
            end

  it { expect(rendered).to have_selector('table.attributes td.work_package_attribute_header + td.story-points', text: story_points.to_s) }
end
